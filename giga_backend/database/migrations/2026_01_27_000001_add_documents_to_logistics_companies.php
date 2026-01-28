<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('logistics_companies', function (Blueprint $table) {
            $table->string('incorporation_document')->nullable()->after('logo_url');
            $table->string('proof_of_address')->nullable()->after('incorporation_document');
        });
    }

    public function down(): void
    {
        Schema::table('logistics_companies', function (Blueprint $table) {
            $table->dropColumn(['incorporation_document', 'proof_of_address']);
        });
    }
};
