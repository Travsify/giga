<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('deliveries', function (Blueprint $label) {
            $label->id();
            $label->foreignId('customer_id')->constrained('users')->onDelete('cascade');
            $label->foreignId('rider_id')->nullable()->constrained('riders')->onDelete('set null');
            $label->string('parcel_type');
            $label->text('description')->nullable();
            $label->string('pickup_address');
            $label->decimal('pickup_lat', 10, 8);
            $label->decimal('pickup_lng', 11, 8);
            $label->string('dropoff_address');
            $label->decimal('dropoff_lat', 10, 8);
            $label->decimal('dropoff_lng', 11, 8);
            $label->decimal('fare', 12, 2);
            $label->string('status')->default('pending'); // pending, assigned, picked_up, in_transit, delivered, cancelled
            $label->timestamp('assigned_at')->nullable();
            $label->timestamp('picked_up_at')->nullable();
            $label->timestamp('delivered_at')->nullable();
            $label->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('deliveries');
    }
};
