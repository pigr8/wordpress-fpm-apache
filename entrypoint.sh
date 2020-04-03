#!/bin/bash
set -euo pipefail

# Applying desidered PUID to user Nobody
sed -i 's/:1000:100:/:'$PUID':100:/g' /etc/passwd

if [ ! -e /var/www/html/index.php ] && [ ! -e /var/www/html/wp-includes/version.php ]; then
    echo "WordPress is missing, installing now."
    curl --silent -f https://api.wordpress.org/secret-key/1.1/salt/ >> /usr/src/wordpress/wp-secrets.php && \
    sed -i "s/'DB_HOST', 'localhost'/'DB_HOST', '$DB_HOST'/g" /usr/src/wordpress/wp-config.php && \
    sed -i "s/'DB_NAME', 'wordpress'/'DB_NAME', '$DB_NAME'/g" /usr/src/wordpress/wp-config.php && \
    sed -i "s/'DB_USER', 'wordpress'/'DB_USER', '$DB_USER'/g" /usr/src/wordpress/wp-config.php && \
    sed -i "s/'DB_PASSWORD', 'localhost'/'DB_PASSWORD', '$DB_PASSWORD'/g" /usr/src/wordpress/wp-config.php && \
    chown -R nobody:users /usr/src/wordpress && \
    cp -R /usr/src/wordpress/* /var/www/html && \
    chown -R nobody:users /var/www/html
fi

unset e
exec "$@"
