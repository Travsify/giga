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
        Schema::table('logistics_companies', function (Blueprint $table) {
            $table->string('vat_number')->nullable()->after('registration_number');
            $table->string('business_email')->nullable()->after('name');
            $table->string('website')->nullable()->after('address');
            $table->string('company_type')->default('LTD')->after('name'); // LTD, PLC, Sole Trader
            $table->decimal('credit_limit', 12, 2)->default(0.00)->after('is_verified');
            $table->decimal('outstanding_balance', 12, 2)->default(0.00)->after('credit_limit');
            $table->json('billing_details')->nullable()->after('address');
        });
    }

    public function down(): void
    {
        Schema::table('logistics_companies', function (Blueprint $table) {
            $table->dropColumn([
                'vat_number',
                'business_email',
                'website',
                'company_type',
                'credit_limit',
                'outstanding_balance',
                'billing_details'
            ]);
        });
    }
};
