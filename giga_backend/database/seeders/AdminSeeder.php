<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@giga.com'],
            [
                'name' => 'Super Admin',
                'password' => Hash::make('GigaAdmin2026!'),
                'role' => 'SuperAdmin',
                'email_verified_at' => now(),
            ]
        );
    }
}
