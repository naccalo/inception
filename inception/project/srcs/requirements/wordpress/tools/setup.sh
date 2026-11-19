#!/bin/bash

set -Eeuo pipefail

: "${DB_HOST:?Missing DB_HOST}"
: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"
: "${DB_PASSWORD:?Missing DB_PASSWORD}"

mkdir -p /run/php

cd /var/www/html

if [ ! -f /usr/local/bin/wp ]; then
    curl -fsSLo /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x /usr/local/bin/wp
fi

until php -r '
try {
    new PDO(
        "mysql:host=" . getenv("DB_HOST") .
        ";dbname=" . getenv("DB_NAME") .
        ";charset=utf8mb4",
        getenv("DB_USER"),
        getenv("DB_PASSWORD")
    );
} catch (Throwable $e) {
    exit(1);
}
'; do
    echo "Waiting for MariaDB..."
    sleep 2
done

echo "MariaDB connection established!"

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$DB_HOST" \
        --allow-root
fi

wp config set DB_NAME "$DB_NAME" --type=constant --allow-root
wp config set DB_USER "$DB_USER" --type=constant --allow-root
wp config set DB_PASSWORD "$DB_PASSWORD" --type=constant --allow-root
wp config set DB_HOST "$DB_HOST" --type=constant --allow-root

if ! wp core is-installed --allow-root >/dev/null 2>&1; then

    : "${DOMAIN_NAME:?Missing DOMAIN_NAME}"
    : "${WP_ADMIN_USER:?Missing WP_ADMIN_USER}"
    : "${WP_ADMIN_PASSWORD:?Missing WP_ADMIN_PASSWORD}"
    : "${WP_ADMIN_EMAIL:?Missing WP_ADMIN_EMAIL}"
    : "${WP_USER:?Missing WP_USER}"
    : "${WP_USER_EMAIL:?Missing WP_USER_EMAIL}"
    : "${WP_USER_PASSWORD:?Missing WP_USER_PASSWORD}"

    wp core install \
        --url="$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root
fi

exec php-fpm8.2 -F
