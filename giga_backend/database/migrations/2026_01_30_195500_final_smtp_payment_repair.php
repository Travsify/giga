<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Force SMTP Hostinger settings directly in DB
        DB::table('app_settings')->where('key', 'mail_host')->update([
            'value' => 'smtp.hostinger.com',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'mail_port')->update([
            'value' => '465',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'mail_encryption')->update([
            'value' => 'ssl',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'mail_username')->update([
            'value' => 'info@usegiga.site',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'mail_password')->update([
            'value' => 'Brevity230./',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'mail_from_address')->update([
            'value' => 'info@usegiga.site',
            'updated_at' => now()
        ]);

        // 2. Force Flutterwave Credentials
        DB::table('app_settings')->where('key', 'flutterwave_public_key')->update([
            'value' => 'FLWPUBK_TEST-bc2862ea59879dcf1c324cd19edb33f0-X',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'flutterwave_secret_key')->update([
            'value' => 'FLWSECK_TEST-589572be5feec85156727ab03e92b1a6-X',
            'updated_at' => now()
        ]);
        DB::table('app_settings')->where('key', 'flutterwave_encryption_key')->update([
            'value' => 'FLWSECK_TESTf8d4fd0b04f8',
            'updated_at' => now()
        ]);

        // 3. Clear all related cache
        Cache::forget('app_setting_mail_host');
        Cache::forget('app_setting_mail_port');
        Cache::forget('app_setting_mail_encryption');
        Cache::forget('app_setting_mail_username');
        Cache::forget('app_setting_mail_password');
        Cache::forget('app_setting_flutterwave_public_key');
        Cache::forget('app_setting_flutterwave_secret_key');
        Cache::forget('app_setting_flutterwave_encryption_key');
        Cache::forget('app_settings_public');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No reverse needed
    }
};
