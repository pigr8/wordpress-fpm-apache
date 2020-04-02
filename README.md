# Introduction

This docker image is build from Alpine base image, with PHP-FPM 7.3 with and Apache2.4.7, and runs Wordpress 5.4 latest version.


# Usage

```
docker run -d -p 8080:80 -e "DB_HOST=localhost" -e "DB_NAME=wordpress" \
-e "DB_USER=wordpress" -e "DB_PASSWORD=wordpress" -e "PUID=1000" \
-v data_dir:/var/www/wordpress/wp-content --name Wordpress pigr8/wordpress-apache-fpm-alpine
```


Description
==================
This container has Apache as the webserver and proxies to PHP-FPM (FastCGI Process Manager), with enabled SSL and HTTP/2 modules. It's my personal container that is not necessary suited for your needs but probably it will.
It has various security fixes and is best used behind a SSL Termination (like HAProxy) for handling the certificate. 


To get Shell Access inside the container
------------------------------------
To get access as root user
```docker exec -it <container-name> /bin/bash```
