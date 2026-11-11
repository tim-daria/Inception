FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        php-fpm \
        php-mysql \
        php-cli \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        php-intl \
        curl \
        ca-certificates \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html && chown www-data:www-data /var/www/html

WORKDIR /var/www/html

COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

EXPOSE 9000

ENTRYPOINT ["/init.sh"]
