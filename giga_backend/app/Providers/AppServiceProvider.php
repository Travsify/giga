<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Force HTTPS in production (Render runs behind a proxy)
        if (app()->environment('production')) {
            URL::forceScheme('https');
        }

        // Apply dynamic settings from database if table exists
        try {
            if (\Illuminate\Support\Facades\Schema::hasTable('app_settings')) {
                $appName = \App\Models\AppSetting::get('app_name');
                if ($appName) {
                    config(['app.name' => $appName]);
                }

                $mailFrom = \App\Models\AppSetting::get('mail_from_address');
                $mailName = \App\Models\AppSetting::get('mail_from_name');

                if ($mailFrom) {
                    config(['mail.from.address' => $mailFrom]);
                }
                if ($mailName) {
                    config(['mail.from.name' => $mailName]);
                }

                $mailHost = \App\Models\AppSetting::get('mail_host');
                $mailPort = \App\Models\AppSetting::get('mail_port');
                $mailUser = \App\Models\AppSetting::get('mail_username');
                $mailPass = \App\Models\AppSetting::get('mail_password');
                $mailEnc = \App\Models\AppSetting::get('mail_encryption');

                if ($mailHost) config(['mail.mailers.smtp.host' => $mailHost]);
                if ($mailPort) config(['mail.mailers.smtp.port' => $mailPort]);
                if ($mailUser) config(['mail.mailers.smtp.username' => $mailUser]);
                if ($mailPass) config(['mail.mailers.smtp.password' => $mailPass]);
                if ($mailEnc) config(['mail.mailers.smtp.encryption' => $mailEnc]);
            }
        } catch (\Exception $e) {
            // Avoid failing if DB not ready
        }
    }
}
