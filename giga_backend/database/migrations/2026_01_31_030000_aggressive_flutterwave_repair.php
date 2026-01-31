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
        $settings = [
            'flutterwave_enabled' => '1',
            'flutterwave_public_key' => 'FLWPUBK_TEST-bc2862ea59879dcf1c324cd19edb33f0-X',
            'flutterwave_secret_key' => 'FLWSECK_TEST-589572be5feec85156727ab03e92b1a6-X',
            'flutterwave_encryption_key' => 'FLWSECK_TESTf8d4fd0b04f8',
        ];

        foreach ($settings as $key => $value) {
            DB::table('app_settings')->updateOrInsert(
                ['key' => $key],
                [
                    'value' => $value,
                    'group' => 'payment',
                    'type' => ($key === 'flutterwave_enabled') ? 'boolean' : 'string',
                    'is_public' => ($key === 'flutterwave_secret_key' || $key === 'flutterwave_encryption_key') ? false : true,
                    'is_sensitive' => ($key === 'flutterwave_secret_key' || $key === 'flutterwave_encryption_key'),
                    'updated_at' => now()
                ]
            );
        }

        Cache::flush();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
