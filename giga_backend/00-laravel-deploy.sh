#!/bin/bash
set -e

echo "Running migrations..."
php artisan migrate --force

echo "Fixing permissions..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache || true

echo "Clearing old caches..."
php artisan config:clear
php artisan route:clear
php artisan cache:clear

echo "Caching config..."
php artisan config:cache

echo "Caching routes..."
php artisan route:cache

echo "Caching view..."
php artisan view:cache

echo "Deployment finished!"
