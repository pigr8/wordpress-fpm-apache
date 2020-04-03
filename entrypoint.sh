#!/bin/bash
set -euo pipefail

sed -i 's/:1000:100:/:'$PUID':100:/g' /etc/passwd

if [ ! -e /var/www/html/index.php ] && [ ! -e /var/www/html/wp-includes/version.php ]; then
    echo "WordPress is missing, installing now."
    curl --silent -f https://api.wordpress.org/secret-key/1.1/salt/ >> /usr/src/wordpress/wp-secrets.php && \
    sed -i "s/localhost/$WORDPRESS_DB_HOST/g" /usr/src/wordpress/wp-config.php && \
    sed -i "s/wordpress/$WORDPRESS_DB_NAME/g" /usr/src/wordpress/wp-config.php && \
    sed -i "s/wordpress/$WORDPRESS_DB_USER/g" /usr/src/wordpress/wp-config.php && \
    sed -i "s/wordpress/$WORDPRESS_DB_PASS/g" /usr/src/wordpress/wp-config.php && \
    chown -R nobody:users /usr/src/wordpress && \
    cp -R /usr/src/wordpress/* /var/www/html && \
    chown -R nobody:users /var/www/html
fi

unset e
exec "$@"
