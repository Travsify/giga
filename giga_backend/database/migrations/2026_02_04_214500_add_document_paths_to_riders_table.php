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
        Schema::table('riders', function (Blueprint $table) {
            if (!Schema::hasColumn('riders', 'driver_license_path')) {
                $table->string('driver_license_path')->nullable()->after('license_number');
            }
            if (!Schema::hasColumn('riders', 'vehicle_license_path')) {
                $table->string('vehicle_license_path')->nullable()->after('driver_license_path');
            }
            if (!Schema::hasColumn('riders', 'vehicle_registration_path')) {
                $table->string('vehicle_registration_path')->nullable()->after('vehicle_license_path');
            }
            if (!Schema::hasColumn('riders', 'insurance_certificate_path')) {
                $table->string('insurance_certificate_path')->nullable()->after('vehicle_registration_path');
            }
            if (!Schema::hasColumn('riders', 'verification_status')) {
                $table->string('verification_status')->default('pending')->after('vehicle_verified');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('riders', function (Blueprint $table) {
            $table->dropColumn([
                'driver_license_path',
                'vehicle_license_path',
                'vehicle_registration_path',
                'insurance_certificate_path',
                'verification_status'
            ]);
        });
    }
};
