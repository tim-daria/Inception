#!/bin/bash
set -e

# MYSQL_PASSWORD=$(cat /run/secrets/db_password)
# WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
# WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)


mkdir -p /run/php
cd /var/www/html

#wait 30s until mariadb is ready
ready=0
for i in $(seq 1 30); do
    if mariadb -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
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

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOST"

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --user_pass="$WP_USER_PASSWORD" --role=author
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F -O
