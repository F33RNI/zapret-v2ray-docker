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

# This script finds container and gracefully stops it if it's running using internal ./stop.sh script
# NOTE: This script must ONLY be executed OUTSIDE the container

# Get container ID
container_id=$(docker ps | grep zapret-v2ray-docker | tail -n1 | awk '{print $1}')
if [ -z "$container_id" ]; then
    echo "Container not found (not started or already stopped)"
    exit 0
fi

# Check if container already stopped
if [ "$(docker container inspect -f '{{.State.Status}}' $container_id)" != "running" ]; then
    echo "Container is not running (not started or already stopped)"
    exit 0
fi

# Call internal script
echo "Stopping container $container_id gracefully"
docker exec "$container_id" ./stop.sh
docker stop "$container_id"
echo -e "\nContainer $container_id stopped"
exit 0
