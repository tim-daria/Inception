#!/bin/bash
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# apply the listen port (DB_PORT, default 3306)
sed "s/DB_PORT/${DB_PORT:-3306}/g" /etc/mysql/mariadb.conf.d/99-custom.cnf > /tmp/99-custom.cnf
mv /tmp/99-custom.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null

    mariadbd --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'$(hostname)';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
fi

exec mariadbd --user=mysql
