#!/bin/bash
set -e

echo "Running migrations..."
php artisan migrate --force

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
