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
        Schema::table('users', function (Blueprint $table) {
            $table->string('referral_code')->unique()->nullable();
            $table->foreignId('referred_by_id')->nullable()->constrained('users')->onDelete('set null');
            $table->decimal('loyalty_points', 10, 2)->default(0);
            $table->string('uk_phone')->nullable();
            $table->string('home_address')->nullable();
            $table->string('work_address')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['referred_by_id']);
            $table->dropColumn(['referral_code', 'referred_by_id', 'loyalty_points', 'uk_phone', 'home_address', 'work_address']);
        });
    }
};
