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
        Schema::table('deliveries', function (Blueprint $table) {
            $table->string('vehicle_type')->nullable()->after('parcel_type');
            $table->string('tracking_number')->unique()->nullable()->after('id');
            $table->string('parcel_size')->nullable()->after('vehicle_type');
            $table->string('estimated_duration')->nullable()->after('fare');
            $table->string('recipient_name')->nullable()->after('estimated_duration');
            $table->string('recipient_phone')->nullable()->after('recipient_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropColumn([
                'vehicle_type',
                'tracking_number',
                'parcel_size',
                'estimated_duration',
                'recipient_name',
                'recipient_phone'
            ]);
        });
    }
};
