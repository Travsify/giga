<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_settings', function (Blueprint $table) {
            $table->id();
            $table->string('group', 50)->index();  // 'app', 'auth', 'payment', 'notification', 'content', 'branding', 'operations'
            $table->string('key', 100)->unique();
            $table->text('value')->nullable();
            $table->string('type', 20)->default('string');  // 'string', 'boolean', 'json', 'integer', 'decimal'
            $table->string('label')->nullable();  // Human-readable label for admin UI
            $table->text('description')->nullable();
            $table->boolean('is_public')->default(false);  // Whether mobile app can access via API
            $table->boolean('is_sensitive')->default(false);  // Whether to mask in UI (passwords, keys)
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_settings');
    }
};
