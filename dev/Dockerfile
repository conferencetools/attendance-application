FROM php:7.3-fpm-alpine3.10

RUN docker-php-ext-install pdo_mysql
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev
RUN docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd
RUN apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev