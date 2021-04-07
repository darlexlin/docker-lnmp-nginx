FROM nginx:1.19.2
ENV TZ=Asia/Shanghai
WORKDIR /etc/nginx/conf.d
COPY sources.list /etc/apt
COPY ddns.conf /etc/nginx/conf.d
RUN apt-get update && \
    apt-get install -y apt-utils vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
VOLUME /etc/nginx/conf.d
EXPOSE 80 443
CMD ["service nginx start","tail -f /dev/null"]