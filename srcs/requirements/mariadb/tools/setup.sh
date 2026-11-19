#!/bin/bash

set -Eeuo pipefail

: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"
: "${DB_PASSWORD:?Missing DB_PASSWORD}"

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
PIDFILE="/run/mysqld/mysqld.pid"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld


if [ ! -d "$DATADIR/mysql" ]; then
    mariadb-install-db --user=mysql --datadir="$DATADIR"
fi

mariadbd \
    --user=mysql \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --pid-file="$PIDFILE" \
    --skip-networking &

MYSQL_PID=$!

cleanup() {
    if kill -0 "$MYSQL_PID" 2>/dev/null; then
        mariadb-admin \
            --protocol=socket \
            --socket="$SOCKET" \
            --user=root shutdown >/dev/null 2>&1 \
        || kill "$MYSQL_PID" 2>/dev/null \
        || true

        wait "$MYSQL_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT
trap 'exit 1' INT TERM

attempt=0

until mariadb-admin \
    --protocol=socket \
    --socket="$SOCKET" \
    --user=root ping --silent >/dev/null 2>&1
do
    if ! kill -0 "$MYSQL_PID" 2>/dev/null; then
        echo "ERROR: MariaDB exited unexpectedly" >&2
        exit 1
    fi

    attempt=$((attempt + 1))

    if [ "$attempt" -ge 60 ]; then
        echo "ERROR: MariaDB did not start within 60 seconds" >&2
        exit 1
    fi

    sleep 1
done

mariadb \
    --protocol=socket \
    --socket="$SOCKET" \
    --user=root <<SQL

CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%'
IDENTIFIED BY '${DB_PASSWORD}';

ALTER USER '${DB_USER}'@'%'
IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.*
TO '${DB_USER}'@'%';

SQL

mariadb \
    --protocol=socket \
    --socket="$SOCKET" \
    --user=root \
    -Nse "SHOW DATABASES LIKE '${DB_NAME}';" |
    grep -Fxq "${DB_NAME}"

mariadb-admin \
    --protocol=socket \
    --socket="$SOCKET" \
    --user=root shutdown

wait "$MYSQL_PID"

trap - EXIT INT TERM

exec mariadbd \
    --user=mysql \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --pid-file="$PIDFILE" \
    --bind-address=0.0.0.0 \
    --port=3306

