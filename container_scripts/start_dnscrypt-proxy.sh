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

# This script sets default DNS server to localhost, creates config symlink, installs and starts service
# NOTE: This script must ONLY be executed inside the container

DNSCRYPT_DIR="/opt/dnscrypt-proxy"
CONFIG_FILE="/configs/dnscrypt-proxy.toml"
CONFIG_FILE_DST="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"

echo "Changing default DNS server to dnscrypt-proxy"
if [ -f "/etc/resolv.conf" ]; then umount -f /etc/resolv.conf; fi
echo "nameserver 127.0.0.1" >/etc/resolv.conf
echo "nameserver ::1" >>/etc/resolv.conf
echo "options edns0" >>/etc/resolv.conf

echo "Creating symlink to config file $CONFIG_FILE_DST -> $CONFIG_FILE"
mkdir -p $(dirname "$CONFIG_FILE_DST")
ln -sf "$CONFIG_FILE" "$CONFIG_FILE_DST"

echo "Installing and restarting dnscrypt-proxy service"
"$DNSCRYPT_DIR/dnscrypt-proxy" -config "$CONFIG_FILE_DST" -service install
"$DNSCRYPT_DIR/dnscrypt-proxy" -service restart

echo -e "\nDone! dnscrypt-proxy service started"
exit 0
