<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inter_state_prices', function (Blueprint $table) {
            $table->id();
            $table->string('origin_state');
            $table->string('destination_state');
            $table->decimal('base_price', 10, 2); // Price for Small
            $table->decimal('medium_surcharge', 10, 2)->default(0);
            $table->decimal('large_surcharge', 10, 2)->default(0);
            $table->integer('delivery_days')->default(2);
            $table->timestamps();

            // Unique index to prevent duplicate routes
            $table->unique(['origin_state', 'destination_state']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inter_state_prices');
    }
};
