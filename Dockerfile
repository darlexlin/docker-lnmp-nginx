FROM ghcr.io/linuxserver/baseimage-alpine

ENV PUID=1000 PGID=1000
ENV TZ Asia/Shanghai

# 安装Nginx和PHP
RUN \
    echo "**** install build packages ****" && \
    apk add --no-cache \
    apache2-utils \
    git \
    libressl3.1-libssl \
    logrotate \
    nano \
    nginx \
    openssl \
    php7=7.0.33-r0 \
    php7-fileinfo \
    php7-fpm \
    php7-json \
    php7-mbstring \
    php7-openssl \
    php7-session \
    php7-simplexml \
    php7-xml \
    php7-xmlwriter \
    php7-mysql \
    php7-zlib && \
    echo "**** configure nginx ****" && \
    echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> \
    /etc/nginx/fastcgi_params && \
    rm -f /etc/nginx/conf.d/default.conf && \
    echo "**** fix logrotate ****" && \
    sed -i "s#/var/log/messages {}.*# #g" /etc/logrotate.conf && \
    sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/periodic/daily/logrotate

#下载并安装V2ray
WORKDIR /root
RUN set -ex && \
    apk add --no-cache wget tzdata openssl ca-certificates --upgrade && \
    wget -q -O v2ray.sh "https://raw.githubusercontent.com/v2fly/docker/master/v2ray.sh" && \
    mkdir -p /etc/v2ray /usr/local/share/v2ray /var/log/v2ray && \
    chmod +x /root/v2ray.sh && \
    /root/v2ray.sh

#绑定工作目录
WORKDIR /config
RUN ln -sf /etc/v2ray /config/v2ray && \
    ln -sf /etc/nginx/conf.d /config/nginx && \
    mkdir -p /config/www  /config/cert  /config/mariadb

#添加配置模板
COPY proxy/ /config/www/proxy/
COPY proxy.conf /config/nginx
COPY website.conf /config/nginx
COPY reverse.conf /config/nginx
COPY config.json /config/v2ray

#暴露工作目录与端口
VOLUME /config
EXPOSE 80 443

CMD [ "/usr/bin/v2ray", "-config", "/etc/v2ray/config.json" ]