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
            $table->string('vehicle_front_path')->nullable()->after('selfie_id_path');
            $table->string('vehicle_side_path')->nullable()->after('vehicle_front_path');
            $table->string('vehicle_interior_path')->nullable()->after('vehicle_side_path');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('riders', function (Blueprint $table) {
            $table->dropColumn(['vehicle_front_path', 'vehicle_side_path', 'vehicle_interior_path']);
        });
    }
};
