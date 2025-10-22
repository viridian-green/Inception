#!/bin/bash
set -e
set -x

# Load passwords from secrets
WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_password)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
WP_PWD=$(cat /run/secrets/wp_usr_password)

echo "Passwords loaded from secrets"

# create directory to use in nginx container later and also to setup the wordpress conf
mkdir -p /var/www/html

cd /var/www/html 
rm -rf * 
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 
chmod +x wp-cli.phar 
mv wp-cli.phar /usr/local/bin/wp
wp core download --allow-root




wp config create \
  --dbname=$MYSQL_DATABASE \
  --dbuser=$MYSQL_USER \
  --dbpass=$MYSQL_PASSWORD \
  --dbhost=mariadb:3306 \
  --path=/var/www/html \
  --allow-root

wp core install --url=$DOMAIN_NAME/ --title=$WP_TITLE --admin_user=$WP_ADMIN_USR --admin_password=$WP_ADMIN_PWD --admin_email=$WP_ADMIN_EMAIL --skip-email --allow-root

wp user update "$WP_ADMIN_USR" --user_pass="$WP_ADMIN_PWD" --allow-root

# Ensure normal user exists and password matches secret
if ! wp user get "$WP_USR" --allow-root &> /dev/null; then
    wp user create "$WP_USR" "$WP_EMAIL" --role=author --user_pass="$WP_PWD" --allow-root
else
    wp user update "$WP_USR" --user_pass="$WP_PWD" --allow-root
fi

wp theme install mission-news --activate --allow-root


wp plugin update --all --allow-root

 
mkdir -p /run/php


/usr/sbin/php-fpm8.2 -F
