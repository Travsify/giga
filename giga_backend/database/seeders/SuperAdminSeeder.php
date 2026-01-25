<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\Hash;

class SuperAdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $adminEmail = 'admin@giga.com';
        
        $user = User::updateOrCreate(
            ['email' => $adminEmail],
            [
                'name' => 'Giga Super Admin',
                'password' => Hash::make('GodMode2026!'),
                'role' => 'SuperAdmin',
                'email_verified_at' => now(),
            ]
        );

        // Ensure admin has a wallet
        Wallet::updateOrCreate(
            ['user_id' => $user->id],
            [
                'balance' => 999999.99,
                'currency' => 'GBP',
            ]
        );
    }
}
