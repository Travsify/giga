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
        Schema::create('delivery_bids', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->onDelete('cascade');
            $table->foreignId('rider_id')->constrained()->onDelete('cascade');
            $table->decimal('bid_amount', 12, 2);
            $table->string('estimated_pickup_time');
            $table->string('status')->default('pending'); // pending, accepted, rejected
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_bids');
    }
};
