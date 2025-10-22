#!/bin/bash
set -e
echo "Starting MariaDB setup..."

#Load passwords from secrets 
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
echo "Passwords loaded from secrets"

# Start MariaDB server in the background using mysqld_safe
echo "Starting MariaDB server..."
mysqld_safe --datadir=/var/lib/mysql --user=mysql &
# Wait for MariaDB to start up

for i in {1..30}; do
    if mysqladmin ping 2>/dev/null; then
        echo "MariaDB started successfully on attempt $i"
        break
    fi
    echo "Waiting for MariaDB to start... $i/30"
    sleep 1
    if [ $i -eq 30 ]; then
        echo "Failed to start MariaDB. Exiting."
        exit 1
    fi
done

# Set up root password if this is the first run
if [ ! -z "$FIRST_START" ]; then
    echo "This is the first start, initializing database..."
else
    # Try to log in with root password, if it fails reset it
    if ! mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" ping 2>/dev/null; then
        echo "Root password needs reset, updating..."
        # Reset root password (this works with a fresh MySQL install)
        mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
    else
        echo "Root password is already set correctly"
    fi
fi

# Set up database and users
echo "Setting up database and users..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
-- Delete users if they exist (to avoid duplicates)
DROP USER IF EXISTS '${MYSQL_USER}'@'%';
DROP USER IF EXISTS '${MYSQL_USER}'@'localhost';
DROP USER IF EXISTS '${MYSQL_USER}'@'wordpress';
DROP USER IF EXISTS '${MYSQL_USER}'@'inception-wordpress-1';
DROP USER IF EXISTS '${MYSQL_USER}'@'inception-wordpress-1.inception';
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'wordpress' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'inception-wordpress-1' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'inception-wordpress-1.inception' IDENTIFIED BY '${MYSQL_PASSWORD}';
-- Grant privileges to all hosts
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'wordpress';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'inception-wordpress-1';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'inception-wordpress-1.inception';
-- Ensure root can connect from localhost and anywhere
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
echo "Database setup complete!"
# Stop MariaDB gracefully
mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
echo "Starting MariaDB server in the foreground..."
# Start MariaDB in the foreground to keep the container running
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql
