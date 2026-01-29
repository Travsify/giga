<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('suite_number')->nullable()->unique()->after('email');
        });

        Schema::create('warehouse_packages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('tracking_number'); // Original carrier tracking
            $table->string('carrier')->nullable(); // Amazon, DHL, etc
            $table->decimal('weight_kg', 8, 2)->default(0);
            $table->text('description')->nullable();
            $table->string('status')->default('received'); // received, paid, shipped, arrived, delivered
            $table->decimal('shipping_fee', 10, 2)->default(0);
            $table->string('photo_url')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('warehouse_packages');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('suite_number');
        });
    }
};
