<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('riders', function (Blueprint $table) {
            $table->string('country', 2)->nullable()->after('vehicle_plate_number'); // 'NG', 'UK'
            $table->string('passport_photo_path')->nullable()->after('country');
            $table->string('nin_path')->nullable()->after('passport_photo_path');
            $table->string('intl_passport_path')->nullable()->after('nin_path');
            $table->string('dvla_license_path')->nullable()->after('intl_passport_path');
            $table->string('brp_path')->nullable()->after('dvla_license_path');
            $table->string('identity_doc_type')->nullable()->after('brp_path'); // 'nin' or 'intl_passport' for NG
        });
    }

    public function down(): void
    {
        Schema::table('riders', function (Blueprint $table) {
            $table->dropColumn([
                'country',
                'passport_photo_path',
                'nin_path',
                'intl_passport_path',
                'dvla_license_path',
                'brp_path',
                'identity_doc_type',
            ]);
        });
    }
};
