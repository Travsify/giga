echo "Ensuring storage directories exist..."
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/framework/cache
mkdir -p storage/logs

echo "Fixing permissions aggressively..."
chmod -R 777 storage bootstrap/cache

echo "Redirecting logs to stderr..."
# This ensures that even if file writes fail, logs go to Render Console
sed -i 's/^LOG_CHANNEL=.*/LOG_CHANNEL=stderr/' .env || echo "LOG_CHANNEL=stderr" >> .env

echo "Fixing ASSET_URL for HTTPS..."
# Force HTTPS for all asset URLs on Render
sed -i 's/^ASSET_URL=.*/ASSET_URL=https:\/\/giga-ytn0.onrender.com/' .env || echo "ASSET_URL=https://giga-ytn0.onrender.com" >> .env

echo "Running migrations..."
php artisan migrate --force

echo "Seeding default settings..."
php artisan db:seed --class=AppSettingsSeeder --force || true

echo "Clearing old caches..."
php artisan config:clear
php artisan route:clear
php artisan cache:clear
php artisan view:clear

echo "Clearing Filament caches..."
php artisan filament:cache-components || true
php artisan icons:cache || true

echo "Caching config..."
php artisan config:cache

echo "Caching routes..."
php artisan route:cache

echo "Caching view..."
php artisan view:cache

echo "Deployment finished!"
