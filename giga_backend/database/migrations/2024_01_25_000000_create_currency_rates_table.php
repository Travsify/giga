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
        Schema::create('currency_rates', function (Blueprint $table) {
            $table->id();
            $table->string('currency_code', 3)->unique(); // USD, NGN, GBP
            $table->string('symbol', 5); // $, ₦, £
            $table->decimal('rate_to_gbp', 12, 4)->default(1.0000); // 1 GBP = X Currency
            $table->boolean('is_active')->default(true);
            $table->boolean('is_base')->default(false); // Helper to identify GBP
            $table->timestamps();
        });

        // Seed default GBP
        DB::table('currency_rates')->insert([
            'currency_code' => 'GBP',
            'symbol' => '£',
            'rate_to_gbp' => 1.0000,
            'is_active' => true,
            'is_base' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        
        // Seed initial NGN
        DB::table('currency_rates')->insert([
            'currency_code' => 'NGN',
            'symbol' => '₦',
            'rate_to_gbp' => 2000.0000, // Example starting rate
            'is_active' => true,
            'is_base' => false,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('currency_rates');
    }
};
