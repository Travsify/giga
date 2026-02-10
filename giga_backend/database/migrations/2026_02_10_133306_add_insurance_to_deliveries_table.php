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
            if (!Schema::hasColumn('deliveries', 'is_insured')) {
                $table->boolean('is_insured')->default(false);
            }
            if (!Schema::hasColumn('deliveries', 'insurance_premium')) {
                $table->decimal('insurance_premium', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('deliveries', 'insured_value')) {
                $table->decimal('insured_value', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('deliveries', 'insurance_policy_no')) {
                $table->string('insurance_policy_no')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropColumn(['is_insured', 'insurance_premium', 'insured_value', 'insurance_policy_no']);
        });
    }
};
