FROM php:7.4-fpm-alpine

LABEL maintainer="Robbio <github.com/pigr8>" \
      architecture="amd64/x86_64" \
      alpine-version="3.11.2" \
      apache-version="2.4.43" \
      php-fpm-version="7.4" \
      wordpress-version="latest" \
      org.opencontainers.image.title="wordpress-apache-fpm-alpine" \
      org.opencontainers.image.description="Wordpress image running on Alpine Linux." \
      org.opencontainers.image.url="https://hub.docker.com/r/pigr8/wordpress-apache-fpm-alpine/" \
      org.opencontainers.image.source="https://github.com/pigr8/wordpress-apache-fpm-alpine"

# persistent dependencies
RUN apk add --no-cache \
# in theory, docker-entrypoint.sh is POSIX-compliant, but priority is a working, consistent image
		bash \
# BusyBox sed is not sufficient for some of our sed expressions
		sed \
# Ghostscript is required for rendering PDF previews
		ghostscript \
# Apache2 with FPM, SSL and HTTP/2 support
		apache2 \
		apache2-proxy \
		apache2-http2 \
		apache2-ssl \
# Supervisor install
		supervisor
# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		freetype-dev \
		imagemagick-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype --with-jpeg; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		mysqli \
		opcache \
		zip \
		pdo \
		pdo_mysql \
	; \
	pecl install imagick-3.4.4; \
	docker-php-ext-enable imagick; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
# https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

VOLUME /var/www/wordpress

ENV WORDPRESS_DB_HOST localhost
ENV WORDPRESS_DB_NAME wordpress
ENV WORDPRESS_DB_USER wordpress
ENV WORDPRESS_DB_PASS wordpress
ENV TZ Europe/Rome
ENV PUID 1000

# Fixes uid/gid of nobody
RUN sed -i 's/:65534:65534:nobody:\/:/:1000:100:nobody:\/var\/www:/g' /etc/passwd
#RUN sed -i 's/user = www-data/user = nobody/g' /usr/local/etc/php-fpm.d/www.conf
#RUN sed -i 's/group = www-data/group = users/g' /usr/local/etc/php-fpm.d/www.conf

# Setting up Wordpress SRC and copy default configs
RUN set -ex; \
	curl -o latest.tar.gz -fSL "https://wordpress.org/latest.tar.gz"; \
	tar -xzf latest.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz
COPY config/wp-config.php /usr/src/wordpress
COPY config/wp-secrets.php /usr/src/wordpress
RUN chmod 644 /usr/src/wordpress/wp-config.php /usr/src/wordpress/wp-secrets.php; \
    chown -R nobody:users /usr/src/wordpress

# Add WP CLI to the system
RUN curl -o /usr/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/bin/wp

# Setting up Apache2 and PHP
COPY config/httpd.conf /etc/apache2/

# Setting up the Container and Supervisor
COPY entrypoint.sh /usr/bin/
COPY config/supervisord.conf /etc/
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
