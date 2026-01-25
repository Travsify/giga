<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class CountriesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $countries = [
            [
                'name' => 'United Kingdom',
                'iso_code' => 'GB',
                'currency_code' => 'GBP',
                'currency_symbol' => '£',
                'phone_code' => '+44',
                'payment_gateways' => ['stripe'],
                'features' => ['instant_delivery', 'scheduled_delivery', 'wallet', 'ulez'],
                'is_active' => true,
                'is_default' => true,
            ],
            [
                'name' => 'Nigeria',
                'iso_code' => 'NG',
                'currency_code' => 'NGN',
                'currency_symbol' => '₦',
                'phone_code' => '+234',
                'payment_gateways' => ['paystack', 'flutterwave'],
                'features' => ['instant_delivery', 'wallet', 'cod'],
                'is_active' => true,
                'is_default' => false,
            ],
            [
                'name' => 'Ghana',
                'iso_code' => 'GH',
                'currency_code' => 'GHS',
                'currency_symbol' => '₵',
                'phone_code' => '+233',
                'payment_gateways' => ['paystack', 'flutterwave'],
                'features' => ['instant_delivery', 'wallet', 'cod'],
                'is_active' => true,
                'is_default' => false,
            ],
            [
                'name' => 'United States',
                'iso_code' => 'US',
                'currency_code' => 'USD',
                'currency_symbol' => '$',
                'phone_code' => '+1',
                'payment_gateways' => ['stripe', 'paypal'],
                'features' => ['instant_delivery', 'scheduled_delivery', 'wallet'],
                'is_active' => true,
                'is_default' => false,
            ],
        ];

        foreach ($countries as $country) {
            \App\Models\Country::updateOrCreate(
                ['iso_code' => $country['iso_code']],
                $country
            );
        }
    }
}
