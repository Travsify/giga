<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('business_invitations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained('logistics_companies')->onDelete('cascade');
            $table->string('email');
            $table->string('role')->default('Member'); // Owner, Admin, Member
            $table->string('token')->unique();
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->unique(['business_id', 'email']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('business_invitations');
    }
};
