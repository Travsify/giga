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
        Schema::create('api_keys', function (Blueprint $row) {
            $row->id();
            $row->foreignId('logistics_company_id')->constrained()->onDelete('cascade');
            $row->string('name');
            $row->string('key')->unique();
            $row->string('prefix')->nullable();
            $row->timestamp('last_used_at')->nullable();
            $row->boolean('is_active')->default(true);
            $row->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('api_keys');
    }
};
