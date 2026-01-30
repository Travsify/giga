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
        // Set Hostinger SMTP settings
        \App\Models\AppSetting::set('mail_mailer', 'smtp', 'email');
        \App\Models\AppSetting::set('mail_host', 'smtp.hostinger.com', 'email');
        \App\Models\AppSetting::set('mail_port', '465', 'email');
        \App\Models\AppSetting::set('mail_encryption', 'ssl', 'email');
        \App\Models\AppSetting::set('mail_username', 'info@usegiga.site', 'email');
        \App\Models\AppSetting::set('mail_password', 'Brevity230./', 'email');
        \App\Models\AppSetting::set('mail_from_address', 'info@usegiga.site', 'email');
        \App\Models\AppSetting::set('mail_from_name', 'MY GIGA', 'email');
        
        // Ensure SMS is also using log for now if not already set
        if (!\App\Models\AppSetting::get('sms_provider')) {
            \App\Models\AppSetting::set('sms_provider', 'log', 'sms');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('hostinger', function (Blueprint $table) {
            //
        });
    }
};
