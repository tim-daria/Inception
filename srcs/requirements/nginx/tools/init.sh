#!/bin/bash
set -e

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/CN=${DOMAIN_NAME}"
fi

sed "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/nginx/site.template \
    > /etc/nginx/conf.d/site.conf

exec nginx -g "daemon off;"
