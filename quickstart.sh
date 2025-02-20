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

# v2ray and dnscrypt-proxy platform and architecture
# See <https://github.com/DNSCrypt/dnscrypt-proxy/releases/latest>
# and <https://github.com/v2fly/v2ray-core/releases/latest> for more info
PLATFORM="linux"
arch_=$(uname -m)
case "$arch_" in
x86_64)
    DNSCRYPT_ARCH="x86_64"
    V2RAY_ARCH="64"
    ;;
i686 | i386)
    DNSCRYPT_ARCH="x86"
    V2RAY_ARCH="32"
    ;;
aarch64 | arm64 | armv8*)
    DNSCRYPT_ARCH="arm64"
    V2RAY_ARCH="arm64-v8a"
    ;;
arm* | sa110*)
    DNSCRYPT_ARCH="arm"
    V2RAY_ARCH="arm32-v7a"
    ;;
*)
    echo "Unknown architecture: $arch_"
    exit 1
    ;;
esac

# Log them
echo "Working on $PLATFORM platform. dnscrypt-proxy architecture: $DNSCRYPT_ARCH, v2ray: $V2RAY_ARCH"

# ############## #
# Download v2ray #
# ############## #

if [ ! -d "./v2ray" ]; then
    download_url=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep -oP '"browser_download_url": "\K.*?\.zip(?=")' | grep -oE ".*v2ray-${PLATFORM}-${V2RAY_ARCH}\.zip")
    if [ -z "$download_url" ]; then
        echo "Error: Unable to find .zip asset in the latest release of v2ray for ${PLATFORM} ${V2RAY_ARCH}"
        exit 1
    fi
    filename=$(basename "$download_url")
    echo -e "\nDownloading $download_url"
    wget "$download_url"

    # Extract it
    unzip "$filename" -d "v2ray"
    rm "$filename"

    # Check
    if [ ! -d "./v2ray" ]; then
        echo "Error downloading or extracting v2ray binaries"
        exit 1
    fi
else
    echo -e "\n./v2ray directory exists! Skipping it"
fi

# ############### #
# Download zapret #
# ############### #

if [ ! -d "./zapret" ]; then
    download_url=$(curl -s https://api.github.com/repos/bol-van/zapret/releases/latest | grep -oP '"browser_download_url": "\K.*?\.tar\.gz(?=")' | grep -v "openwrt")
    if [ -z "$download_url" ]; then
        echo "Error: Unable to find .tar.gz asset in the latest release of zapret"
        exit 1
    fi
    filename=$(basename "$download_url")
    echo -e "\nDownloading $download_url"
    wget "$download_url"

    # Extract it
    if ! tar -xvzf "$filename"; then
        tar xvzf "$filename"
    fi
    rm "$filename"
    mv "./${filename%.*.*}" ./zapret

    # Check
    if [ ! -d "./zapret" ]; then
        echo "Error downloading or extracting zapret binaries"
        exit 1
    fi
else
    echo -e "\n./zapret directory exists! Skipping it"
fi

# ####################### #
# Download dnscrypt-proxy #
# ####################### #

if [ ! -d "./dnscrypt-proxy" ]; then
    download_url=$(curl -s https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | grep -oP '"browser_download_url": "\K.*?\.tar\.gz(?=")' | grep -oE ".*dnscrypt-proxy-${PLATFORM}_${DNSCRYPT_ARCH}-.*\.tar\.gz")
    if [ -z "$download_url" ]; then
        echo "Error: Unable to find .tar.gz asset in the latest release of dnscrypt-proxy for ${PLATFORM} ${DNSCRYPT_ARCH}"
        exit 1
    fi
    filename=$(basename "$download_url")
    echo -e "\nDownloading $download_url"
    wget "$download_url"

    # Extract it
    if ! tar -xvzf "$filename"; then
        tar xvzf "$filename"
    fi
    rm "$filename"
    mv "./${PLATFORM}-${DNSCRYPT_ARCH}" ./dnscrypt-proxy

    # Check
    if [ ! -d "./dnscrypt-proxy" ]; then
        echo "Error downloading or extracting dnscrypt-proxy binaries"
        exit 1
    fi
else
    echo -e "\n./dnscrypt-proxy directory exists! Skipping it"
fi

# ############### #
# Build container #
# ############### #

# Make sure container is stopped
./stop.sh
docker kill zapret-v2ray-docker

# Build and start the container
echo -e "\nBuilding and starting the container"
docker-compose up --build --detach

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
