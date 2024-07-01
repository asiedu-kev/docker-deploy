#!/bin/sh

chmod -R 777 storage/
chmod -R 777 bootstrap/cache/

# Storage Symlink Creation
php artisan storage:link

php artisan optimize

php-fpm -y /usr/local/etc/php-fpm.conf -R
