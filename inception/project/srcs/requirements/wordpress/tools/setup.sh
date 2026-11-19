#!/bin/bash

set -e

mkdir -p /run/php

cd /var/www/html

# Download WP-CLI
if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Wait for MariaDB
until php -r "
try {
    new PDO(
        'mysql:host=mariadb;dbname=' . getenv('MYSQL_DATABASE'),
        getenv('MYSQL_USER'),
        getenv('MYSQL_PASSWORD')
    );
} catch (Exception \$e) {
    exit(1);
}
"; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# Download WordPress
if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb" \
        --allow-root

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
