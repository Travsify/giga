<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('riders', function (Blueprint $label) {
            $label->id();
            $label->foreignId('user_id')->constrained()->onDelete('cascade');
            $label->foreignId('logistics_company_id')->nullable()->constrained()->onDelete('set null');
            $label->string('license_number')->unique();
            $label->string('vehicle_type')->default('bike'); // bike, van, truck
            $label->string('vehicle_plate_number')->unique();
            $label->boolean('is_online')->default(false);
            $label->decimal('current_lat', 10, 8)->nullable();
            $label->decimal('current_lng', 11, 8)->nullable();
            $label->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('riders');
    }
};
