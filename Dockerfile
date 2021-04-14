FROM nginx:mainline-alpine-perl

# 环境变量
ENV PUID=1000 PGID=1000
ENV TZ Asia/Shanghai

# 守护程序 s6 overlay 的版本
ARG OVERLAY_VERSION="v2.2.0.3"
ARG OVERLAY_ARCH="amd64"

# 添加守护程序 s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}-installer /tmp/
RUN chmod +x /tmp/s6-overlay-${OVERLAY_ARCH}-installer && /tmp/s6-overlay-${OVERLAY_ARCH}-installer / && rm /tmp/s6-overlay-${OVERLAY_ARCH}-installer
COPY patch/ /tmp/patch

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

RUN \
    echo "**** install build packages ****" && \
    apk add --no-cache --virtual=build-dependencies \
	curl \
	patch \
	tar && \
    echo "**** install runtime packages ****" && \
    apk add --no-cache \
	bash \
	ca-certificates \
	coreutils \
	procps \
	shadow \
	tzdata && \
    echo "**** create abc user and make our folders ****" && \
    groupmod -g 1000 users && \
    useradd -u 911 -U -d /config -s /bin/false abc && \
    usermod -G users abc && \
    mkdir -p \
	/app \
	/config \
	/defaults && \
    mv /usr/bin/with-contenv /usr/bin/with-contenvb && \
    patch -u /etc/s6/init/init-stage2 -i /tmp/patch/etc/s6/init/init-stage2.patch && \
    echo "**** cleanup ****" && \
    apk del --purge \
	build-dependencies && \
    rm -rf \
	/tmp/*

#下载并安装V2ray
WORKDIR /root
ARG TARGETPLATFORM="linux/amd64"
ARG TAG="4.37.3"
# USER root
RUN set -ex && \
    apk add --no-cache wget tzdata openssl ca-certificates --upgrade && \
    wget -q -O v2ray.sh "https://raw.githubusercontent.com/v2fly/docker/master/v2ray.sh" && \
    mkdir -p /etc/v2ray /usr/local/share/v2ray /var/log/v2ray && \
    chmod +x /root/v2ray.sh && \
    /root/v2ray.sh "${TARGETPLATFORM}" "${TAG}"

#绑定工作目录
WORKDIR /config

#添加本地文件
COPY root/ /

#暴露工作目录与端口
VOLUME /config
EXPOSE 80 443

ENTRYPOINT ["/init"]
CMD [ "/usr/bin/v2ray", "-config", "/config/v2ray/config.json" ]