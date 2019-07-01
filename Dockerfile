FROM ubuntu:18.04

WORKDIR /tmp
RUN apt-get update
RUN apt install wget build-essential git tree gcc libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev libgd-dev google-perftools libgoogle-perftools-dev libperl-dev -y

RUN mkdir /tmp/moreheaders && mkdir /tmp/nginx && mkdir /tmp/openssl

RUN wget https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz
RUN tar -xvzf /tmp/v0.33.tar.gz -C /tmp/moreheaders --strip-components=1

RUN wget https://www.openssl.org/source/openssl-1.1.1c.tar.gz
RUN tar -xvzf /tmp/openssl-1.1.1c.tar.gz -C /tmp/openssl --strip-components=1

WORKDIR /tmp/openssl

RUN ./config -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)' \
        && make && make install

RUN ldconfig

WORKDIR /tmp
RUN wget http://nginx.org/download/nginx-1.17.1.tar.gz
RUN tar -xvzf /tmp/nginx-1.17.1.tar.gz -C /tmp/nginx --strip-components=1

RUN addgroup --system nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false nginx

RUN mkdir /usr/lib/nginx && mkdir /usr/lib/nginx/modules

WORKDIR /tmp/nginx
RUN ./configure \
        --prefix=/usr/share/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --user=nginx \
        --group=nginx \
        --build=Ubuntu \
        --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
        --with-openssl-opt=no-nextprotoneg \
        --with-openssl-opt=no-weak-ssl-ciphers \
        --with-openssl-opt=no-ssl3 \
        --with-pcre-jit \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_sub_module \
        --with-http_stub_status_module \
        --with-http_v2_module \
        --with-http_secure_link_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-debug \
        --with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
        --add-module=/tmp/moreheaders \
        && make && make install

WORKDIR /tmp

RUN touch /run/nginx.pid

RUN chown nginx:nginx /etc/nginx /etc/nginx/nginx.conf /var/log/nginx \
        /usr/share/nginx /run/nginx.pid /usr/lib/nginx/ \
        /usr/lib/nginx/modules /etc/nginx/* /usr/sbin/nginx

EXPOSE 80
EXPOSE 443

# USER nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log

# COPY content /usr/share/nginx/html
# COPY conf /etc/nginx
VOLUME html:/usr/share/nginx/html
VOLUME config:/etc/nginx

STOPSIGNAL SIGTERM

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
