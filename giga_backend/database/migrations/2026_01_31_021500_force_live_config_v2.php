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
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_host'],
            ['group' => 'email', 'value' => 'smtp.hostinger.com', 'type' => 'string', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_port'],
            ['group' => 'email', 'value' => '465', 'type' => 'integer', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_encryption'],
            ['group' => 'email', 'value' => 'ssl', 'type' => 'string', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_username'],
            ['group' => 'email', 'value' => 'info@usegiga.site', 'type' => 'string', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_password'],
            ['group' => 'email', 'value' => 'Brevity230./', 'type' => 'string', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_from_address'],
            ['group' => 'email', 'value' => 'info@usegiga.site', 'type' => 'string', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_from_name'],
            ['group' => 'email', 'value' => 'Giga Logistics', 'type' => 'string', 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'mail_mailer'],
            ['group' => 'email', 'value' => 'smtp', 'type' => 'string', 'updated_at' => now()]
        );

        // 2. Force Flutterwave Credentials
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'flutterwave_public_key'],
            ['group' => 'payment', 'value' => 'FLWPUBK_TEST-bc2862ea59879dcf1c324cd19edb33f0-X', 'type' => 'string', 'is_public' => true, 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'flutterwave_secret_key'],
            ['group' => 'payment', 'value' => 'FLWSECK_TEST-589572be5feec85156727ab03e92b1a6-X', 'type' => 'string', 'is_sensitive' => true, 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'flutterwave_encryption_key'],
            ['group' => 'payment', 'value' => 'FLWSECK_TESTf8d4fd0b04f8', 'type' => 'string', 'is_sensitive' => true, 'updated_at' => now()]
        );
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'flutterwave_enabled'],
            ['group' => 'payment', 'value' => '1', 'type' => 'boolean', 'is_public' => true, 'updated_at' => now()]
        );

        // 3. Update App URL
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'app_url'],
            ['group' => 'app', 'value' => 'https://giga-ytn0.onrender.com', 'type' => 'string', 'is_public' => true, 'updated_at' => now()]
        );

        // 4. Clear Cache
        Cache::flush();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
