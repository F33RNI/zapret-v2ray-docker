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

FROM debian:stable-slim
LABEL maintainer="Fern Lane"

WORKDIR /root

# Upgrade everything and download essentials
RUN apt-get update && \
    apt-get install -y init && \
    apt-get upgrade -y && \
    apt-get install -y systemd curl wget nano unzip && \
    apt-get clean all

# Setup the environment
# Original code from <https://github.com/8hrsk/zapret-docker-proxy>
ENV container=docker
COPY container.target /etc/systemd/system/container.target
RUN ln -sf /etc/systemd/system/container.target /etc/systemd/system/default.target
ENTRYPOINT ["/sbin/init"]
STOPSIGNAL SIGRTMIN+3
RUN systemctl set-default multi-user.target

# Install v2ray
COPY v2ray /opt/v2ray
RUN ln -s /opt/v2ray/v2ray /usr/local/bin/v2ray
COPY container_scripts/start_v2ray.sh /opt/v2ray/start_v2ray.sh
RUN chmod +x /opt/v2ray/start_v2ray.sh

# Install dnscrypt-proxy
COPY dnscrypt-proxy /opt/dnscrypt-proxy
COPY container_scripts/start_dnscrypt-proxy.sh /opt/dnscrypt-proxy/start_dnscrypt-proxy.sh
RUN chmod +x /opt/dnscrypt-proxy/start_dnscrypt-proxy.sh

# Install zapret
COPY zapret /opt/zapret
WORKDIR /opt/zapret
RUN ./install_bin.sh && \
    echo "1" | ./install_prereq.sh
WORKDIR /root
COPY container_scripts/start_zapret.sh /opt/zapret/start_zapret.sh
RUN chmod +x /opt/zapret/start_zapret.sh

CMD [ "/bin/bash" ]
