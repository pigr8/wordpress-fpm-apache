#!/bin/bash
set -euo pipefail

sed -i 's/:1000:100:/:'$PUID':100:/g' /etc/passwd

if [ ! -e /var/www/wordpress/index.php ] && [ ! -e /var/www/wordpress/wp-includes/version.php ]; then
    echo "WordPress is missing, installing now."
    curl --silent -f https://api.wordpress.org/secret-key/1.1/salt/ >> /usr/src/wordpress/wp-secrets.php
#   if [[ "$DB_HOST" && "$DB_NAME" && "$DB_USER" && "$DB_PASS" ]]; then
        sed -i "s/localhost/$DB_HOST/g" /usr/src/wordpress/wp-config.php
        sed -i "s/wordpress/$DB_NAME/g" /usr/src/wordpress/wp-config.php
        sed -i "s/wordpress/$DB_USER/g" /usr/src/wordpress/wp-config.php
        sed -i "s/wordpress/$DB_PASSWORD/g" /usr/src/wordpress/wp-config.php
#       sed -i "s/$table_prefix = 'wp_';/$table_prefix = 'wp_';\n\n\/\/ If we're behind a proxy server and using HTTPS, we need to alert Wordpress of that fact\n\/\/ see also http:\/\/codex.wordpress.org\/Administration_Over_SSL#Using_a_Reverse_Proxy\nif (isset($\_SERVER['HTTP_X_FORWARDED_PROTO']) \&\& $\_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\n\t$\_SERVER['HTTPS'] = 'on';\n}\n/g" /var/www/html/wp-config.php
#   fi
    cp -R /usr/src/wordpress /var/www
    chown -R nobody:users /var/www/wordpress
fi

unset e
exec "$@"
