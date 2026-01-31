<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Log;
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

                $mailMailer = \App\Models\AppSetting::get('mail_mailer');
                $mailFrom = \App\Models\AppSetting::get('mail_from_address');
                $mailName = \App\Models\AppSetting::get('mail_from_name');
                $mailHost = \App\Models\AppSetting::get('mail_host');
                $mailPort = \App\Models\AppSetting::get('mail_port');
                $mailUser = \App\Models\AppSetting::get('mail_username');
                $mailPass = \App\Models\AppSetting::get('mail_password');
                $mailEnc  = \App\Models\AppSetting::get('mail_encryption');

                if ($mailMailer) {
                    config(['mail.default' => $mailMailer]);
                }
                
                if ($mailFrom) {
                    config(['mail.from.address' => $mailFrom]);
                }

                // SECURE OVERRIDE: Hostinger requires FROM to match USERNAME
                if ($mailHost === 'smtp.hostinger.com' || env('MAIL_HOST') === 'smtp.hostinger.com') {
                    config(['mail.from.address' => 'info@usegiga.site']);
                    Log::info("SMTP From Address forced to info@usegiga.site for Hostinger.");
                }
                if ($mailName) {
                    config(['mail.from.name' => $mailName]);
                }

                // Prioritize Hostinger or ignore if DB contains Mailgun
                if ($mailHost && $mailHost !== 'smtp.mailgun.org') {
                    config(['mail.mailers.smtp.host' => $mailHost]);
                    Log::info("SMTP Host set from DB: $mailHost");
                } elseif (env('MAIL_HOST') === 'smtp.hostinger.com') {
                    config(['mail.mailers.smtp.host' => 'smtp.hostinger.com']);
                    Log::info("SMTP Host prioritized from ENV: smtp.hostinger.com");
                }

                if ($mailPort && $mailPort != '587') {
                    config(['mail.mailers.smtp.port' => $mailPort]);
                    Log::info("SMTP Port set from DB: $mailPort");
                } elseif (env('MAIL_HOST') === 'smtp.hostinger.com') {
                    config(['mail.mailers.smtp.port' => 465]);
                }

                if ($mailUser) {
                    config(['mail.mailers.smtp.username' => $mailUser]);
                }
                if ($mailPass) {
                    config(['mail.mailers.smtp.password' => $mailPass]);
                }

                if ($mailEnc) {
                    config(['mail.mailers.smtp.encryption' => $mailEnc]);
                    Log::info("SMTP Encryption set to: $mailEnc");
                }

                // Force re-initialization of the mailer with these new configs
                \Illuminate\Support\Facades\Mail::forgetMailers();
            }
        } catch (\Exception $e) {
            // Avoid failing if DB not ready
        }
    }
}
