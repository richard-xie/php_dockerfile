#ADD file:69848cb51056edaf120230b6f218a79968ac797295c2cef6728332e1801357be in / 
#CMD ["/bin/sh"]
FROM php7.2-fpm-alpine
#RUN apk add dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c
ENV PHPIZE_DEPS \
        autoconf \
        file \
        g++ \
        gcc \
        libc-dev \
        make \
        pkg-config \
        re2c
RUN apk add --no-cache --virtual .persistent-deps ca-certificates curl tar xz openssl
RUN set -x \
 && addgroup -g 82 -S www-data \
 && adduser -u 82 -D -S -G www-data www-data
ENV PHP_INI_DIR=/usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d
ENV PHP_EXTRA_CONFIGURE_ARGS=--enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data
ENV PHP_CFLAGS \
        -fstack-protector-strong \
        -fpic \
        -fpie \
        -O2
ENV PHP_CPPFLAGS \
        -fstack-protector-strong \
        -fpic \
        -fpie \
        -O2
ENV PHP_LDFLAGS \
        -Wl,-O1 -Wl,--hash-style \
        both \
        -pie
ENV GPG_KEYS=A917B1ECDA84AEC2B568FED6F50ABC807BD5DCD0 528995BFEDFBA7191D46839EF9BA0ADA31CBD89E 1729F83938DA44E27BA0F4D3DBDB397470D12172
ENV PHP_VERSION=7.1.13
ENV PHP_URL=https://secure.php.net/get/php-7.1.13.tar.xz/from/this/mirror PHP_ASC_URL=https://secure.php.net/get/php-7.1.13.tar.xz.asc/from/this/mirror
ENV PHP_SHA256=1a0b3f2fb61959b57a3ee01793a77ed3f19bde5aa90c43dcacc85ea32f64fc10 PHP_MD5=
RUN set -xe; apk add --no-cache --virtual .fetch-deps gnupg  ; mkdir -p /usr/src;  cd /usr/src; wget -O php.tar.xz "$PHP_URL"; if [ -n "$PHP_SHA256" ]; then echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -;  fi;  if [ -n "$PHP_MD5" ]; then echo "$PHP_MD5 *php.tar.xz" | md5sum -c -;  fi; if [ -n "$PHP_ASC_URL" ]; then wget -O php.tar.xz.asc "$PHP_ASC_URL"; export GNUPGHOME="$(mktemp -d)"; for key in $GPG_KEYS; do  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; done; gpg --batch --verify php.tar.xz.asc php.tar.xz; rm -rf "$GNUPGHOME";  fi; apk del .fetch-deps
COPY file:207c686e3fed4f71f8a7b245d8dcae9c9048d276a326d82b553c12a90af0c0ca in /usr/local/bin/ 
RUN set -xe \
 && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS coreutils curl-dev libedit-dev openssl-dev libxml2-dev sqlite-dev \
 && export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
 && docker-php-source extract \
 && cd /usr/src/php \
 && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
 && ./configure --build="$gnuArch" --with-config-file-path="$PHP_INI_DIR" --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" --disable-cgi --enable-ftp --enable-mbstring --enable-mysqlnd --with-curl --with-libedit --with-openssl --with-zlib $(test "$gnuArch" = 's390x-linux-gnu' \
 && echo '--without-pcre-jit') $PHP_EXTRA_CONFIGURE_ARGS \
 && make -j "$(nproc)" \
 && make install \
 && { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
 && make clean \
 && cd / \
 && docker-php-source delete \
 && runDeps="$( scanelf --needed --nobanner --format '%n#p' --recursive /usr/local  | tr ',' '\n'  | sort -u  | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'  )" \
 && apk add --no-cache --virtual .php-rundeps $runDeps \
 && apk del .build-deps \
 && pecl update-channels \
 && rm -rf /tmp/pear ~/.pearrc
COPY multi:f9544e5c6b9d1d1292fca43464fe1e77b631547ac2baa8503de318853c0536d0 in /usr/local/bin/ 
ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html
RUN set -ex \
 && cd /usr/local/etc \
 && if [ -d php-fpm.d ]; then sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; cp php-fpm.d/www.conf.default php-fpm.d/www.conf;  else mkdir php-fpm.d; cp php-fpm.conf.default php-fpm.d/www.conf; {  echo '[global]';  echo 'include=etc/php-fpm.d/*.conf'; } | tee php-fpm.conf;  fi \
 && { echo '[global]'; echo 'error_log = /proc/self/fd/2'; echo; echo '[www]'; echo '; if we send this to /proc/self/fd/1, it never appears'; echo 'access.log = /proc/self/fd/2'; echo; echo 'clear_env = no'; echo; echo '; Ensure worker stdout and stderr are sent to the main error log.'; echo 'catch_workers_output = yes';  } | tee php-fpm.d/docker.conf \
 && { echo '[global]'; echo 'daemonize = no'; echo; echo '[www]'; echo 'listen = [::]:9000';  } | tee php-fpm.d/zz-docker.conf
EXPOSE 9000/tcp
CMD ["php-fpm"]
ENV ZEROMQ_VERSION=4.1.5
ENV RABBITMQ_VERSION=v0.8.0
ENV PHP_AMQP_VERSION=v1.9.3
ENV PHP_REDIS_VERSION=3.1.4
ENV PHP_ZEROMQ_VERSION=master
ENV PHP_MONGO_VERSION=1.3.4
ENV IGBINARY_VERSION=2.0.4
ENV PHP_MEMCACHED_VERSION=3.0.3
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
 && echo @testing http://mirrors.aliyun.com/alpine/edge/testing >> /etc/apk/repositories \
 && apk add --update --no-cache tzdata vim supervisor \
 && cp -r -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && apk del tzdata
ENV PHPIZE_DEPS=autoconf cmake file g++ gcc libc-dev pcre-dev  perl-dev  zlib-dev  linux-headers gnupg libxslt-dev  libcurl augeas-dev  ca-certificates  musl-dev  icu-dev  libpq libffi-dev make git pkgconf  openssl-dev cyrus-sasl-dev  bzip2-dev  gettext-dev re2c
RUN apk add --no-cache --virtual .persistent-deps icu-dev libmcrypt-dev libssl1.0 libsodium-dev  zeromq-dev postgresql-dev libxml2-dev  libmemcached-dev freetype-dev libjpeg-turbo-dev  libpng-dev
RUN set -xe \
 && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
 && docker-php-ext-configure bcmath --enable-bcmath \
 && docker-php-ext-configure intl --enable-intl \
 && docker-php-ext-configure pcntl --enable-pcntl \
 && docker-php-ext-configure mcrypt --with-mcrypt \
 && docker-php-ext-configure mysqli --with-mysqli \
 && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
 && docker-php-ext-configure pdo_pgsql --with-pgsql \
 && docker-php-ext-configure soap --enable-soap \
 && docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && docker-php-ext-configure opcache --enable-opcache \
 && docker-php-ext-configure sockets --enable-sockets \
 && docker-php-ext-install bcmath intl mcrypt mysqli pcntl pdo_mysql pdo_pgsql soap gd opcache sockets \
 && git clone --branch ${RABBITMQ_VERSION} https://github.com/alanxz/rabbitmq-c.git /tmp/rabbitmq \
 && cd /tmp/rabbitmq \
 && mkdir build \
 && cd build \
 && cmake .. \
 && cmake --build . --target install \
 && cp -r /usr/local/lib64/* /usr/lib/ \
 && git clone --branch ${PHP_AMQP_VERSION} https://github.com/pdezwart/php-amqp.git /tmp/php-amqp \
 && cd /tmp/php-amqp \
 && phpize \
 && ./configure \
 && make \
 && make install \
 && make test \
 && echo 'extension=amqp.so' >> /usr/local/etc/php/conf.d/docker-php-ext-amqp.ini \
 && pecl install channel://pecl.php.net/zmq-1.1.3 \
 && docker-php-ext-enable zmq.so \
 && pecl install swoole \
 && docker-php-ext-enable swoole.so \
 && pecl install igbinary \
 && docker-php-ext-enable igbinary.so \
 && pecl install msgpack \
 && docker-php-ext-enable msgpack.so \
 && pecl install memcached \
 && docker-php-ext-enable memcached.so \
 && pecl install redis \
 && docker-php-ext-enable redis.so \
 && pecl install mongodb \
 && docker-php-ext-enable mongodb.so \
 && apk del .build-deps \
 && rm -rf /tmp/*
WORKDIR /var/www
COPY file:58de67948a658ee91609d51a14ca25ada058ca0714ece040c2eeedf6f98bb646 in /usr/local/etc/php/ 
COPY file:d5789403af0cd9543b096feaef158fbe61713e9292dc13d1f2357f90509f30f5 in /usr/local/etc/php/conf.d/ 
COPY file:03c91f02a662b7d3d30e0a448a142dc9d6352447202b0abeb68e8e521c3d778d in /usr/local/etc/ 
COPY dir:15e29fa967a2733a3868ab670e575ce6b475c6b92a6ca42438408cc857523c31 in /usr/local/etc/pool.d 
