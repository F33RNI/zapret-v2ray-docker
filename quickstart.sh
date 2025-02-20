#!/usr/bin/env bash

# This file is part of the zapret-v2ray-docker distribution.
# See <https://github.com/F33RNI/zapret-v2ray-docker> for more info.
#
# Copyright (c) 2025 Fern Lane.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# This script downloads v2ray, zapret and dnscrypt-proxy, builds and starts container and starts all services
# NOTE: This script must ONLY be executed OUTSIDE the container

_VERSION="1.0.dev3"

# Print some cool looking ascii art :)
echo "                ,           _,                 .      .        "
echo "__. _.._ ._. _ -+- ___ .  ,'_) ._. _.  . ___  _| _  _.;_/ _ ._."
echo " /_(_][_)[  (/, |       \/ /_. [  (_]\\_|     (_](_)(_.| \\(/,[  "
echo "      |                              ._|                       "
echo -e "\nVersion: $_VERSION\n"

# Load environment variables and perform basic check
source .env
if [ -z "$DNSCRYPT_DIR" ] || [ -z "$V2RAY_DIR" ] || [ -z "$ZAPRET_DIR" ]; then
    echo "ERROR: Some environment variables are empty / not specified"
    exit 1
fi

# Platform and architecture for programs
# See <https://github.com/DNSCrypt/dnscrypt-proxy/releases/latest>
# and <https://github.com/v2fly/v2ray-core/releases/latest> for more info
#
# You can specify them as environment variables PLATFORM, DNSCRYPT_ARCH, V2RAY_ARCH
if [ -z "$PLATFORM" ]; then PLATFORM="linux"; fi
if [ -z "$DNSCRYPT_ARCH" ] || [ -z "$V2RAY_ARCH" ]; then
    arch_=$(uname -m)
    case "$arch_" in
    x86_64)
        _dnscrypt_arch="x86_64"
        _v2ray_arch="64"
        ;;
    i686 | i386)
        _dnscrypt_arch="x86"
        _v2ray_arch="32"
        ;;
    aarch64 | arm64 | armv8*)
        _dnscrypt_arch="arm64"
        _v2ray_arch="arm64-v8a"
        ;;
    arm* | sa110*)
        _dnscrypt_arch="arm"
        _v2ray_arch="arm32-v7a"
        ;;
    *)
        echo "Unknown architecture: $arch_"
        exit 1
        ;;
    esac
    if [ -z "$DNSCRYPT_ARCH" ]; then DNSCRYPT_ARCH="$_dnscrypt_arch"; fi
    if [ -z "$V2RAY_ARCH" ]; then V2RAY_ARCH="$_v2ray_arch"; fi
fi
echo "Working on $PLATFORM platform. dnscrypt-proxy target architecture: $DNSCRYPT_ARCH, v2ray: $V2RAY_ARCH"

# Wrapper that checks and downloads program
# Args:
#   1: Path to target directory (asset will be unpacked into it)
#   2: Link to asset (.tar.gz or .zip)
#   3: Latest tag name for simple version checking (grep -oP '"tag_name": "\K.*?(?=")')
check_download() {
    local target_dir="$1"
    local download_url="$2"
    local latest_tag_name="$3"

    # Debug arguments
    echo "$download_url @ $latest_tag_name -> $target_dir"

    # Directory and version file exist, and it's the latest version
    if [ -d "$target_dir" ] && [ -f "$target_dir/tag_name.txt" ] && grep -q "$latest_tag_name" "$target_dir/tag_name.txt"; then
        echo "Skipping $target_dir ($latest_tag_name already exists)"
        return
    fi

    # Check download link
    if [ -z "$download_url" ]; then
        echo "ERROR: No download URL for $target_dir (check platform and architecture)"
        exit 1
    fi

    # Delete existing dir
    if [ -d "$target_dir" ]; then
        echo "The downloaded $target_dir is either not the latest version or doesn't contain a version tag. Deleting"
        rm -rf "$target_dir"
    fi

    # Download and check
    local download_filename=$(basename "$download_url")
    echo -e "\nDownloading $download_url"
    curl --output "$download_filename" --location "$download_url"
    if [ ! -f "$download_filename" ]; then
        echo "ERROR: Unable to download $download_filename"
        exit 1
    fi

    # Extract and check
    if [[ "$download_filename" == *.zip ]]; then
        echo "Unzipping into $target_dir using unzip command"
        unzip "$download_filename" -d "$target_dir"
    else
        echo "Extracting into $target_dir using tar command"
        mkdir -p "$target_dir"
        if ! tar -xvzf "$download_filename" -C "$target_dir" --strip-components 1; then
            tar xvzf "$download_filename" -C "$target_dir" --strip-components 1
        fi
    fi
    if [ -z "$(ls -A $target_dir)" ]; then
        echo "ERROR: Unable to extract $download_filename"
        exit 1
    fi

    # Delete archive
    echo "Deleting archive $download_filename"
    rm "$download_filename"

    # Write latest tag name
    echo "$latest_tag_name" >"$target_dir/tag_name.txt"

    echo "$target_dir downloaded successfully"
}

# ################# #
# Download programs #
# ################# #

# Download dnscrypt-proxy
release_json=$(curl -s https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest)
download_url=$(echo "$release_json" | grep -oP '"browser_download_url": "\K.*?\.tar\.gz(?=")' | grep -oE ".*dnscrypt-proxy-${PLATFORM}_${DNSCRYPT_ARCH}-.*\.tar\.gz")
latest_tag_name=$(echo "$release_json" | grep -oP '"tag_name": "\K.*?(?=")')
check_download "$DNSCRYPT_DIR" "$download_url" "$latest_tag_name"

# Download v2ray
release_json=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest)
download_url=$(echo "$release_json" | grep -oP '"browser_download_url": "\K.*?\.zip(?=")' | grep -oE ".*v2ray-${PLATFORM}-${V2RAY_ARCH}\.zip")
latest_tag_name=$(echo "$release_json" | grep -oP '"tag_name": "\K.*?(?=")')
check_download "$V2RAY_DIR" "$download_url" "$latest_tag_name"

# Download zapret
release_json=$(curl -s https://api.github.com/repos/bol-van/zapret/releases/latest)
download_url=$(echo "$release_json" | grep -oP '"browser_download_url": "\K.*?\.tar\.gz(?=")' | grep -v "openwrt")
latest_tag_name=$(echo "$release_json" | grep -oP '"tag_name": "\K.*?(?=")')
check_download "$ZAPRET_DIR" "$download_url" "$latest_tag_name"

# ############### #
# Build container #
# ############### #

# Make sure container is stopped
./stop.sh
docker kill zapret-v2ray-docker

# Build and start the container
echo -e "\nBuilding and starting the container"
if ! docker-compose up --build --detach; then
    echo "ERROR: docker-compose finished with error"
    exit 1
fi

# Wait for container to be ready
echo -e "\nWaiting for container to start..."
attempt=0
until docker exec zapret-v2ray-docker echo "Container is ready! Check logs in logs/ directory for more info"; do
    attempt=$((attempt + 1))
    if [ $attempt -ge 3 ]; then
        echo "ERROR: Timeout waiting for container to start! Please check errors / config / build files"
        exit 1
    fi
    sleep 1
done
