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

# This script starts the container
# NOTE: This script must ONLY be executed OUTSIDE the container

# Load environment variables and perform basic check
source .env
if [ -z "$PORTS" ] ||
    [ -z "$LOGS_DIR" ] ||
    [ -z "$DNSCRYPT_CONFIG_FILE" ] ||
    [ -z "$V2RAY_CONFIG_FILE" ] ||
    [ -z "$ZAPRET_CONFIG_FILE" ] ||
    [ -z "$_CONFIGS_DIR_INT" ] ||
    [ -z "$_LOGS_DIR_INT" ]; then
    echo "ERROR: Some environment variables are empty / not specified"
    exit 1
fi

# Build port arguments
ports_arg="-p $(echo "$PORTS" | awk '{$1=$1};1' | sed -r 's/ +/ -p /g')"
echo "Ports: $ports_arg"

# Make sure container is stopped
echo "Stopping and removing old containers"
./stop.sh rm

# Start the container
echo -e "\nStarting container"
if ! docker run \
    --cap-add NET_RAW \
    --cap-add NET_ADMIN \
    $ports_arg \
    --volume "${DNSCRYPT_CONFIG_FILE}:${_CONFIGS_DIR_INT}/dnscrypt-proxy.toml" \
    --volume "${V2RAY_CONFIG_FILE}:${_CONFIGS_DIR_INT}/v2ray.json" \
    --volume "${ZAPRET_CONFIG_FILE}:${_CONFIGS_DIR_INT}/zapret.conf" \
    --volume "${LOGS_DIR}:${_LOGS_DIR_INT}" \
    --name "zapret-v2ray-docker" \
    -d "f33rni/zapret-v2ray-docker"; then
    echo -e "\nERROR: Unable to start container"
    exit 1
fi

# Wait for container to be ready
echo -e "\nWaiting for container to start..."
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -ge 3 ]; then
        echo "ERROR: Timeout waiting for container to start! Please check errors / config / build files"
        exit 1
    fi
    sleep 1

    # Get container ID
    container_id=$(docker ps | grep zapret-v2ray-docker | tail -n1 | awk '{print $1}')
    if [ -z "$container_id" ]; then continue; fi

    # Check if it's running
    if [ "$(docker container inspect -f '{{.State.Status}}' $container_id)" != "running" ]; then continue; fi

    echo -e "\nContainer is ready! Check logs in logs/ directory for more info"
    exit 0
done
