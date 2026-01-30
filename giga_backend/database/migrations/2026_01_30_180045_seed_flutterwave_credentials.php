<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        \App\Models\AppSetting::set('flutterwave_public_key', 'FLWPUBK_TEST-bc2862ea59879dcf1c324cd19edb33f0-X', 'payment');
        \App\Models\AppSetting::set('flutterwave_secret_key', 'FLWSECK_TEST-589572be5feec85156727ab03e92b1a6-X', 'payment');
        \App\Models\AppSetting::set('flutterwave_encryption_key', 'FLWSECK_TESTf8d4fd0b04f8', 'payment');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
