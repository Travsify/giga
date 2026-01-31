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
        // 1. Correct the from address to match the authenticated user
        DB::table('app_settings')->where('key', 'mail_from_address')->update([
            'value' => 'info@usegiga.site',
            'updated_at' => now()
        ]);

        // 2. Ensure mail_from_name is professional
        DB::table('app_settings')->where('key', 'mail_from_name')->update([
            'value' => 'Giga Logistics',
            'updated_at' => now()
        ]);

        // 3. Clear Cache
        Cache::flush();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
