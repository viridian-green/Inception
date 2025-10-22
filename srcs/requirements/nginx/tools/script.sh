#!/bin/bash

set -e

: "${DOMAIN_NAME:=localhost}"

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/ssl/certs/nginx-selfsigned.crt ]; then
    echo "🔐 Generating self-signed SSL certificate for ${DOMAIN_NAME}..."

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=DE/ST=Berlin/L=Berlin/O=42/CN=${DOMAIN_NAME}"

    chown root:www-data /etc/ssl/private/nginx-selfsigned.key
    chmod 644 /etc/ssl/certs/nginx-selfsigned.crt

    echo "✅ SSL certificate generated at /etc/ssl/"
else
    echo "ℹ️ SSL certificate already exists. Skipping generation."
fi

echo "
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${DOMAIN_NAME};
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;" > /etc/nginx/sites-available/default


echo '
    ssl_protocols TLSv1.3;

    index index.php;
    root /var/www/html;
    location ~ [^/]\.php(/|$) { 
            try_files $uri =404;
            fastcgi_pass wordpress:9000;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
} ' >>  /etc/nginx/sites-available/default



echo "🧪 Testing nginx configuration..."
nginx -t
echo "✅ Nginx configuration test passed."

echo "🚀 Starting Nginx..."

exec nginx -g "daemon off;"
