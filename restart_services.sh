#!/bin/bash

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

# This script restarts all services (execute it if config files have changed)
# NOTE: This script must ONLY be executed OUTSIDE the container

DNSCRYPT_DIR="/opt/dnscrypt-proxy"

echo "Restarting dnscrypt-proxy"
docker exec zapret-v2ray-docker "$DNSCRYPT_DIR/dnscrypt-proxy" -service restart
docker exec zapret-v2ray-docker journalctl -u dnscrypt-proxy.service -n 5 --no-pager

echo -e "\nRestarting zapret"
docker exec zapret-v2ray-docker systemctl restart zapret
docker exec zapret-v2ray-docker journalctl -u zapret.service -n 5 --no-pager

echo -e "\nRestarting v2ray"
docker exec zapret-v2ray-docker systemctl restart v2ray
docker exec zapret-v2ray-docker journalctl -u v2ray.service -n 5 --no-pager

echo -e "\nDone! Services restarted"
exit 0
