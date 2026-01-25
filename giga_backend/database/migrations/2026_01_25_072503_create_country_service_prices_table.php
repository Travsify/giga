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
        Schema::create('country_service_prices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('country_id')->constrained()->cascadeOnDelete();
            $table->foreignId('service_id')->constrained()->cascadeOnDelete();
            $table->decimal('base_price', 10, 2)->default(0);
            $table->decimal('price_per_km', 10, 2)->default(0);
            $table->decimal('price_per_min', 10, 2)->default(0);
            $table->decimal('minimum_fare', 10, 2)->default(0);
            $table->decimal('commission_percentage', 5, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->unique(['country_id', 'service_id']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('country_service_prices');
    }
};
