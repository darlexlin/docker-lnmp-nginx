FROM nginx:mainline-alpine-perl

ENV DEBIAN_FRONTEND noninteractive
ENV PUID=1000 PGID=1000
ENV TZ Asia/Shanghai

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
RUN ln -s /etc/v2ray /config/v2ray && \
    ln -s /etc/nginx/conf.d /config/nginx

#添加配置模板
COPY proxy.conf /config/nginx
COPY website.conf /config/nginx
COPY reverse.conf /config/nginx

#暴露
VOLUME /config
EXPOSE 80 443

CMD ["nginx" "-g" "daemon off;"]