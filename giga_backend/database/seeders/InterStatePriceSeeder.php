<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\InterStatePrice;

class InterStatePriceSeeder extends Seeder
{
    public function run(): void
    {
        $routes = [
            [
                'origin_state' => 'Lagos',
                'destination_state' => 'Abuja',
                'base_price' => 3500, // Small
                'medium_surcharge' => 1000,
                'large_surcharge' => 2500,
                'delivery_days' => 2,
            ],
            [
                'origin_state' => 'Lagos',
                'destination_state' => 'Rivers', // Port Harcourt
                'base_price' => 4500,
                'medium_surcharge' => 1200,
                'large_surcharge' => 3000,
                'delivery_days' => 3,
            ],
            [
                'origin_state' => 'Abuja',
                'destination_state' => 'Lagos',
                'base_price' => 3500,
                'medium_surcharge' => 1000,
                'large_surcharge' => 2500,
                'delivery_days' => 2,
            ],
        ];

        foreach ($routes as $route) {
            InterStatePrice::create($route);
        }
    }
}
