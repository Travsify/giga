<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * PERMANENT FIX: This migration is now a NO-OP.
 * The email_verification_codes table has been manually corrected
 * via /fix-schema-manual endpoint with the following structure:
 * - user_id: nullable unsignedBigInteger
 * - email: nullable string (indexed)
 * - code: string(7)
 * - expires_at: timestamp
 * - created_at: nullable timestamp
 */
return new class extends Migration
{
    public function up(): void
    {
        // NO-OP: Schema already correct. This migration just marks itself as complete.
    }

    public function down(): void
    {
        // NO-OP
    }
};
