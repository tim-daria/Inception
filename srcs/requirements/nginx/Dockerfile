FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
        openssl \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default \
    && rm -rf /var/www/html

COPY conf/site.template /etc/nginx/site.template
COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 443

ENTRYPOINT ["/init.sh"]
