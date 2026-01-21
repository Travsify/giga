# Giga Backend Manual Setup Guide

## Issue

Composer installation is experiencing persistent stalling issues on this environment.

## Alternative Setup Methods

### Option 1: Use Pre-built Laravel with Composer (Recommended if composer works)

```bash
# Clear all caches
composer clear-cache

# Try with different flags
composer install --no-scripts --no-plugins --prefer-dist

# If that fails, try without prefer-dist
composer install --no-scripts --no-plugins
```

### Option 2: Manual Vendor Directory Setup

If composer continues to fail, you can:

1. **On another machine with working composer:**

    ```bash
    composer create-project laravel/laravel temp_project
    cd temp_project
    composer install
    # Zip the vendor directory
    ```

2. **Transfer the vendor folder** to this project

3. **Generate app key:**
    ```bash
    php artisan key:generate
    ```

### Option 3: Use Docker (Most Reliable)

```bash
# Create docker-compose.yml in giga_backend/
docker-compose up -d
docker-compose exec app composer install
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate
```

## Current Project Status

### ✅ Already Completed

- Database migrations created
- API controllers implemented
- Eloquent models defined
- API routes configured
- .env file created

### ⏳ Pending (Requires vendor/)

- Composer dependencies installation
- Application key generation
- Database migration execution
- API testing

## Testing Without Full Installation

You can test the Flutter app with mock data:

1. The AuthProvider already has mock authentication
2. All UI screens are functional
3. Navigation works end-to-end

## When Composer Completes

Run these commands in order:

```bash
# 1. Generate application key
php artisan key:generate

# 2. Configure database in .env
# Edit DB_DATABASE, DB_USERNAME, DB_PASSWORD

# 3. Run migrations
php artisan migrate

# 4. Install Sanctum (for API authentication)
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate

# 5. Start development server
php artisan serve
```

## Troubleshooting

### If "composer install" hangs:

- Press Ctrl+C to cancel
- Run: `composer diagnose`
- Check: `composer config --list`
- Try: `composer install --profile` to see where it stalls

### If you get memory errors:

```bash
php -d memory_limit=-1 composer.phar install
```

### If you get timeout errors:

```bash
composer config --global process-timeout 2000
composer install
```

## Contact Points

- Laravel Documentation: https://laravel.com/docs
- Composer Issues: https://github.com/composer/composer/issues
