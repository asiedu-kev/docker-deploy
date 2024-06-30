FROM node:14-bullseye AS node
FROM php:8.2.0-fpm

# Arguments defined in docker-compose.yml
#ARG NOVA_USERNAME
#ARG NOVA_PASSWORD

COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Linux user
ENV user=app
ENV uid=1000

# Update memory for php
ENV PHP_MEMORY_LIMIT=2048M
ENV PHP_UPLOAD_MAX_FILESIZE=40
ENV PHP_POST_MAX_SIZE=40
ENV PHP_MAX_EXECUTION_TIME=40

# Composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_VENDOR_DIR=/var/www/vendor

# Node
ENV NODE_PATH=/var/www/node_modules

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

RUN apt-get install -y libpq-dev libicu-dev g++\
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

RUN apt-get install -y libzip-dev \
    && docker-php-ext-install zip \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl

RUN docker-php-ext-enable opcache

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www
COPY . /var/www

## Authenticate with Nova using credentials
#RUN composer config http-basic.nova.laravel.com $NOVA_USERNAME $NOVA_PASSWORD

# Install php dependencies
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Install node dependencies
RUN npm install
