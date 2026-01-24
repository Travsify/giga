<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PromoSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('promos')->insert([
            [
                'code' => 'NHSHERO',
                'title' => 'NHS Heroes',
                'description' => 'Free standard delivery for NHS staff on orders over £20.',
                'discount_type' => 'fixed',
                'discount_value' => 12.00,
                'min_order_amount' => 20.00,
                'category' => 'NHS',
                'is_active' => true,
                'created_at' => now(),
            ],
            [
                'code' => 'STUDENT20',
                'title' => 'Student Discount',
                'description' => '20% off all deliveries for verified students.',
                'discount_type' => 'percentage',
                'discount_value' => 20.00,
                'min_order_amount' => 0.00,
                'category' => 'Student',
                'is_active' => true,
                'created_at' => now(),
            ],
            [
                'code' => 'GIGAPLUS',
                'title' => 'Giga+ Premium',
                'description' => 'Exclusive rates for our Giga+ members.',
                'discount_type' => 'percentage',
                'discount_value' => 25.00,
                'min_order_amount' => 0.00,
                'category' => 'Premium',
                'is_active' => true,
                'created_at' => now(),
            ],
        ]);
    }
}
