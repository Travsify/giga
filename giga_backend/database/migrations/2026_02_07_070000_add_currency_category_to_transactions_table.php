<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('transactions', 'currency')) {
                $table->string('currency')->default('NGN'); // Default to NGN or appropriate default
            }
            if (!Schema::hasColumn('transactions', 'category')) {
                $table->string('category')->nullable(); // e.g., 'transfer', 'gift_card', 'bill_payment'
            }
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (Schema::hasColumn('transactions', 'currency')) {
                $table->dropColumn('currency');
            }
            if (Schema::hasColumn('transactions', 'category')) {
                $table->dropColumn('category');
            }
        });
    }
};
