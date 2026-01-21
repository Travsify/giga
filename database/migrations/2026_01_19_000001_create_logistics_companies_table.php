<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('logistics_companies', function (Blueprint $label) {
            $label->id();
            $label->foreignId('user_id')->constrained()->onDelete('cascade');
            $label->string('name');
            $label->string('registration_number')->unique();
            $label->string('address');
            $label->string('contact_phone');
            $label->string('logo_url')->nullable();
            $label->boolean('is_verified')->default(false);
            $label->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('logistics_companies');
    }
};
