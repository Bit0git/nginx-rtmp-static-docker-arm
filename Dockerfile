FROM arm32v6/alpine AS build 
ENV NGINX_VERSION nginx-1.15.0
ENV NGINX_RTMP_MODULE_VERSION 1.2.1
RUN apk update && apk upgrade && apk add gcc g++ make wget file openssl-dev pcre-dev zlib-dev
RUN NGINX_VERSION=nginx-1.15.8 && wget http://nginx.org/download/${NGINX_VERSION}.tar.gz && tar zxf ${NGINX_VERSION}.tar.gz && wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && tar -zxf v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
cd ${NGINX_VERSION} && ls -lha && \
./configure --with-pcre --with-pcre-jit --with-http_v2_module --with-http_ssl_module --with-http_slice_module --with-stream --with-stream_ssl_preread_module --sbin-path=/usr/local/sbin/nginx --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
sed -i "s/-lpcre -lssl -lcrypto -lz/-static -lpcre -lssl -lcrypto -lz/g" objs/Makefile && make -j2 CFLAGS=-Os LDFLAGS=-static && make install && \
strip -s /usr/local/sbin/nginx &&  rm -rf /etc/nginx/*.default

FROM arm32v6/alpine
LABEL maintainer="suconghou@gmail.com"
COPY --from=build /usr/local/sbin/nginx /usr/local/sbin/nginx
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /var/log/nginx /var/log/nginx
COPY nginx2.conf /etc/nginx/nginx.conf
WORKDIR /etc/nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 1935
CMD ["nginx", "-g", "daemon off;"]
