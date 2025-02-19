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

# This script copies service file, creates config symlink, replaces config format, enables and starts v2ray service
# NOTE: This script must ONLY be executed inside the container

V2RAY_DIR="/opt/v2ray"
CONFIG_FILE="/configs/v2ray.json"
CONFIG_FILE_DST="/usr/local/etc/v2ray/config.json"

echo "Creating symlink to config file $CONFIG_FILE_DST -> $CONFIG_FILE"
mkdir -p $(dirname "$CONFIG_FILE_DST")
ln -sf "$CONFIG_FILE" "$CONFIG_FILE_DST"

echo "Copying service file and replacing config format"
cp "$V2RAY_DIR/systemd/system/v2ray.service" /usr/lib/systemd/system/v2ray.service
sed -i "s|-config|-format jsonv5 -config|g" /usr/lib/systemd/system/v2ray.service

echo "Enabling and restarting v2ray service"
systemctl daemon-reload
systemctl enable v2ray
systemctl restart v2ray

echo "Done! v2ray service started"
exit 0
