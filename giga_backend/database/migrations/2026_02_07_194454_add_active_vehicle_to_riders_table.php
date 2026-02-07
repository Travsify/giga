<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('riders', function (Blueprint $table) {
            $table->foreignId('active_vehicle_id')->nullable()->after('logistics_company_id')->constrained('vehicles')->nullOnDelete();
        });

        // Migrate existing vehicle data
        DB::table('riders')->whereNotNull('vehicle_plate_number')->orderBy('id')->chunk(100, function ($riders) {
            foreach ($riders as $rider) {
                // Determine verification status based on existing fields
                $isVerified = $rider->vehicle_verified;
                $status = $rider->vehicle_verified ? 'verified' : 'pending';

                // Create new Vehicle record
                $vehicleId = DB::table('vehicles')->insertGetId([
                    'rider_id' => $rider->id,
                    'vehicle_type' => $rider->vehicle_type,
                    'vehicle_plate_number' => $rider->vehicle_plate_number,
                    'is_verified' => $isVerified,
                    'verification_status' => $status,
                    
                    // Copy document paths
                    'vehicle_front_path' => $rider->vehicle_front_path,
                    'vehicle_side_path' => $rider->vehicle_side_path,
                    'vehicle_interior_path' => $rider->vehicle_interior_path,
                    'vehicle_license_path' => $rider->vehicle_license_path,
                    'vehicle_registration_path' => $rider->vehicle_registration_path,
                    'insurance_certificate_path' => $rider->insurance_certificate_path,
                    
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Set as active vehicle
                DB::table('riders')->where('id', $rider->id)->update([
                    'active_vehicle_id' => $vehicleId,
                    'has_vehicle' => true // Ensure this is true if they have data
                ]);
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('riders', function (Blueprint $table) {
            $table->dropForeign(['active_vehicle_id']);
            $table->dropColumn('active_vehicle_id');
        });
    }
};
