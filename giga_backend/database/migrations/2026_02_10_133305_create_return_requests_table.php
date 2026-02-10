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
        if (!Schema::hasTable('return_requests')) {
            Schema::create('return_requests', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->onDelete('cascade');
                $table->string('retailer_name'); // Amazon, ASOS, etc.
                $table->string('order_number')->nullable();
                $table->string('return_method'); // no_label, qr_code, pre_printed
                $table->string('status')->default('pending');
                $table->foreignId('delivery_id')->nullable()->constrained()->onDelete('set null');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('return_requests');
    }
};
