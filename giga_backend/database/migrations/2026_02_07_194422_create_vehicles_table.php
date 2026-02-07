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
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->string('vehicle_type')->nullable(); // Car, Bike, Van, Truck
            $table->string('vehicle_plate_number')->nullable();
            $table->string('make')->nullable();
            $table->string('model')->nullable();
            $table->string('color')->nullable();
            $table->string('year')->nullable();
            
            // Verification Status
            $table->boolean('is_verified')->default(false);
            $table->string('verification_status')->default('pending'); // pending, submitted, verified, rejected
            $table->text('rejection_reason')->nullable();
            $table->json('verification_errors')->nullable();

            // Document Paths (Mirroring Rider table for now)
            $table->string('vehicle_front_path')->nullable();
            $table->string('vehicle_side_path')->nullable();
            $table->string('vehicle_interior_path')->nullable();
            $table->string('vehicle_license_path')->nullable(); // Roadworthiness
            $table->string('vehicle_registration_path')->nullable();
            $table->string('insurance_certificate_path')->nullable();

            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
