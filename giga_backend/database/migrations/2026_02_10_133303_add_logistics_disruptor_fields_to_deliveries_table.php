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
            if (!Schema::hasColumn('deliveries', 'escrow_pin')) {
                $table->string('escrow_pin', 10)->nullable();
            }
            if (!Schema::hasColumn('deliveries', 'is_escrow')) {
                $table->boolean('is_escrow')->default(false);
            }
            if (!Schema::hasColumn('deliveries', 'escrow_status')) {
                $table->string('escrow_status')->nullable(); // pending, released, disputed
            }
            if (!Schema::hasColumn('deliveries', 'green_choice')) {
                $table->string('green_choice')->nullable(); // none, ev, bicycle
            }
            if (!Schema::hasColumn('deliveries', 'service_category')) {
                $table->string('service_category')->default('standard'); // standard, priority, legal_swift
            }
            if (!Schema::hasColumn('deliveries', 'recipient_phone')) {
                $table->string('recipient_phone')->nullable(); // For send-to-contact
            }
            if (!Schema::hasColumn('deliveries', 'location_requested')) {
                $table->boolean('location_requested')->default(false);
            }
            if (!Schema::hasColumn('deliveries', 'group_id')) {
                $table->string('group_id')->nullable(); // For multi-stop grouping
            }
        });
    }

    public function down(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropColumn([
                'escrow_pin', 'is_escrow', 'escrow_status', 
                'green_choice', 'service_category', 
                'recipient_phone', 'location_requested', 'group_id'
            ]);
        });
    }
};
