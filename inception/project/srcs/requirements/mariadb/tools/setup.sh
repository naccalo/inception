#!/bin/bash

# Param && Security control

set -Euo pipefail

: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"
: "${DB_PASSWORD:?Missing DB_PASSWORD}"
: "${DB_HOST:?Missing DB_HOST}"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

mariadbd --user=mysql --skip-networking & MYSQL_PID=$!

until mariadb-admin --user=root ping --silent; do
    if ! kill -0 "$MYSQL_PID" 2>/dev/null; then
        exit 1
    fi
    sleep 1
done

# Sql queries

mariadb <<SQL

CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%'
IDENTIFIED BY '${DB_PASSWORD}';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';

SQL

# Check after creating DDBB

mariadb -N -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep -Fxq "${DB_NAME}" || exit 1

wait "$MYSQL_PID"

exit 0
