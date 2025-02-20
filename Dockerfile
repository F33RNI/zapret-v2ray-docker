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

# Internal paths to programs (where they will be installed) inside the container (copied from host)
ENV _DNSCRYPT_DIR_INT="/opt/dnscrypt-proxy"
ENV _V2RAY_DIR_INT="/opt/v2ray"
ENV _ZAPRET_DIR_INT="/opt/zapret"

# Internal paths to symbolic links of config files inside the container
ENV _DNSCRYPT_CONFIG_FILE_INT="${_DNSCRYPT_DIR_INT}/dnscrypt-proxy.toml"
ENV _V2RAY_CONFIG_FILE_INT="${_V2RAY_DIR_INT}/config.json"
ENV _ZAPRET_CONFIG_FILE_INT="${_ZAPRET_DIR_INT}/config"

# Arguments from docker-compose.yml
ARG TZ
RUN test -n "$TZ"
ENV TZ=${TZ}
ARG DNSCRYPT_DIR
RUN test -n "$DNSCRYPT_DIR"
ENV DNSCRYPT_DIR=${DNSCRYPT_DIR}
ARG V2RAY_DIR
RUN test -n "$V2RAY_DIR"
ENV V2RAY_DIR=${V2RAY_DIR}
ARG ZAPRET_DIR
RUN test -n "$ZAPRET_DIR"
ENV ZAPRET_DIR=${ZAPRET_DIR}
ARG _CONFIGS_DIR_INT
RUN test -n "$_CONFIGS_DIR_INT"
ENV _CONFIGS_DIR_INT=${_CONFIGS_DIR_INT}
ARG _LOGS_DIR_INT
RUN test -n "$_LOGS_DIR_INT"
ENV _LOGS_DIR_INT=${_LOGS_DIR_INT}

# Config and log files in mounted volume inside the container
ENV _DNSCRYPT_CONFIG_FILE="${_CONFIGS_DIR_INT}/dnscrypt-proxy.toml"
ENV _V2RAY_CONFIG_FILE="${_CONFIGS_DIR_INT}/v2ray.json"
ENV _ZAPRET_CONFIG_FILE="${_CONFIGS_DIR_INT}/zapret.conf"
ENV _DNSCRYPT_LOG_FILE="${_LOGS_DIR_INT}/dnscrypt-proxy.log"
ENV _V2RAY_LOG_FILE="${_LOGS_DIR_INT}/v2ray.log"
ENV _ZAPRET_LOG_FILE="${_LOGS_DIR_INT}/zapret.log"

ENV container="docker"
WORKDIR /root

# Upgrade everything and install essentials
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y dist-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y install ca-certificates tzdata
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get -y autoclean
RUN DEBIAN_FRONTEND=noninteractive apt-get clean all

# Set timezone
RUN echo "$TZ" >/etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

# Install dnscrypt-proxy
COPY ${DNSCRYPT_DIR} ${_DNSCRYPT_DIR_INT}
WORKDIR ${_DNSCRYPT_DIR_INT}
RUN /usr/bin/env bash -c 'echo -e "nameserver 127.0.0.1\nnameserver ::1\noptions edns0" >/etc/resolv.conf.override'
RUN mkdir -p $(dirname "$_DNSCRYPT_CONFIG_FILE_INT")
RUN ln -sf "$_DNSCRYPT_CONFIG_FILE" "$_DNSCRYPT_CONFIG_FILE_INT"
RUN "./dnscrypt-proxy" -config "$_DNSCRYPT_CONFIG_FILE_INT" -service install

# Install v2ray
COPY ${V2RAY_DIR} ${_V2RAY_DIR_INT}
WORKDIR ${_V2RAY_DIR_INT}
RUN mkdir -p $(dirname "$_V2RAY_CONFIG_FILE_INT")
RUN ln -sf "$_V2RAY_CONFIG_FILE" "$_V2RAY_CONFIG_FILE_INT"

# Install zapret
COPY ${ZAPRET_DIR} ${_ZAPRET_DIR_INT}
WORKDIR ${_ZAPRET_DIR_INT}
RUN ./install_bin.sh
RUN echo "1" | ./install_prereq.sh
RUN echo "Y" | ./install_easy.sh
RUN mkdir -p $(dirname "$_ZAPRET_CONFIG_FILE_INT")
RUN ln -sf "$_ZAPRET_CONFIG_FILE" "$_ZAPRET_CONFIG_FILE_INT"

WORKDIR /root

# Copy scripts
COPY container_scripts/entrypoint.sh .
COPY container_scripts/restart.sh .
COPY container_scripts/stop.sh .
RUN chmod +x ./entrypoint.sh ./restart.sh ./stop.sh

# Start everything
CMD ["/usr/bin/env", "bash", "-c", "./entrypoint.sh"]
