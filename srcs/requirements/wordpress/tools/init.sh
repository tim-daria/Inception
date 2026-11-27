#!/bin/bash
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)


mkdir -p /run/php
cd /var/www/html

# full DB host used by WordPress (host:port)
DB_HOSTFULL="$MYSQL_HOST:${DB_PORT:-3306}"

#wait 30s until mariadb is ready
ready=0
for i in $(seq 1 30); do
    if mariadb -h "$MYSQL_HOST" -P "${DB_PORT:-3306}" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        "$MYSQL_DATABASE" -e "SELECT 1;" > /dev/null 2>&1; then
        ready=1
        break
    fi
    echo "Waiting for MariaDB ($i/30)..."
    sleep 1
done
if [ "$ready" -ne 1 ]; then
    echo "MariaDB is not available" >&2
    exit 1
fi

if [ "${NGINX_PORT:-443}" = "443" ]; then
    WP_URL="https://${DOMAIN_NAME}"
else
    WP_URL="https://${DOMAIN_NAME}:${NGINX_PORT}"
fi

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$DB_HOSTFULL"

    wp core install --allow-root \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --user_pass="$WP_USER_PASSWORD" --role=author
fi

# keep the WordPress config and URL in sync with the current DB host/port
# and domain/port (no-op if unchanged, applies after a port change on start)
# NB: wp config set first — it only edits wp-config.php and needs no DB access
wp config set DB_HOST "$DB_HOSTFULL" --allow-root
wp option update siteurl "$WP_URL" --allow-root
wp option update home "$WP_URL" --allow-root

# apply the php-fpm listen port (WP_PORT, default 9000)
sed "s/WP_PORT/${WP_PORT:-9000}/g" /etc/php/8.2/fpm/pool.d/www.conf > /tmp/www.conf
mv /tmp/www.conf /etc/php/8.2/fpm/pool.d/www.conf

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F -O
