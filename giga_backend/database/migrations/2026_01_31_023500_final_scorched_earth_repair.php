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
        // 1. Delete all existing SMTP related settings to ensure a clean slate
        $keys = [
            'mail_mailer', 'mail_host', 'mail_port', 'mail_username', 
            'mail_password', 'mail_encryption', 'mail_from_address', 'mail_from_name',
            'flutterwave_public_key', 'flutterwave_secret_key', 'flutterwave_encryption_key', 'flutterwave_enabled'
        ];
        
        DB::table('app_settings')->whereIn('key', $keys)->delete();

        // 2. Insert fresh Hostinger SMTP settings
        DB::table('app_settings')->insert([
            ['group' => 'email', 'key' => 'mail_mailer', 'value' => 'smtp', 'type' => 'string', 'is_public' => false, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_host', 'value' => 'smtp.hostinger.com', 'type' => 'string', 'is_public' => false, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_port', 'value' => '465', 'type' => 'integer', 'is_public' => false, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_username', 'value' => 'info@usegiga.site', 'type' => 'string', 'is_public' => false, 'is_sensitive' => true, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_password', 'value' => 'Brevity230./', 'type' => 'string', 'is_public' => false, 'is_sensitive' => true, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_encryption', 'value' => 'ssl', 'type' => 'string', 'is_public' => false, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_from_address', 'value' => 'info@usegiga.site', 'type' => 'string', 'is_public' => false, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'email', 'key' => 'mail_from_name', 'value' => 'Giga Logistics', 'type' => 'string', 'is_public' => false, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // 3. Insert fresh Flutterwave settings
        DB::table('app_settings')->insert([
            ['group' => 'payment', 'key' => 'flutterwave_enabled', 'value' => '1', 'type' => 'boolean', 'is_public' => true, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'payment', 'key' => 'flutterwave_public_key', 'value' => 'FLWPUBK_TEST-bc2862ea59879dcf1c324cd19edb33f0-X', 'type' => 'string', 'is_public' => true, 'is_sensitive' => false, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'payment', 'key' => 'flutterwave_secret_key', 'value' => 'FLWSECK_TEST-589572be5feec85156727ab03e92b1a6-X', 'type' => 'string', 'is_public' => false, 'is_sensitive' => true, 'created_at' => now(), 'updated_at' => now()],
            ['group' => 'payment', 'key' => 'flutterwave_encryption_key', 'value' => 'FLWSECK_TESTf8d4fd0b04f8', 'type' => 'string', 'is_public' => false, 'is_sensitive' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // 4. Force Flush Cache
        Cache::flush();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
