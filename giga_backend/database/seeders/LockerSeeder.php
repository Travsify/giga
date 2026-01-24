<?php

namespace Database\Seeders;

use App\Models\Locker;
use Illuminate\Database\Seeder;

class LockerSeeder extends Seeder
{
    public function run(): void
    {
        $lockers = [
            [
                'name' => 'Giga Locker - Trafalgar',
                'address' => 'Charing Cross Station, London WC2N 5HF',
                'latitude' => 51.5074,
                'longitude' => -0.1278,
                'status' => 'available',
                'total_compartments' => 20,
                'available_compartments' => 12,
            ],
            [
                'name' => 'Giga Locker - Oxford Circus',
                'address' => 'Oxford Circus Station, London W1B 3AG',
                'latitude' => 51.5155,
                'longitude' => -0.1419,
                'status' => 'full',
                'total_compartments' => 15,
                'available_compartments' => 0,
            ],
            [
                'name' => 'Giga Locker - The Shard',
                'address' => '32 London Bridge St, London SE1 9SG',
                'latitude' => 51.5045,
                'longitude' => -0.0865,
                'status' => 'available',
                'total_compartments' => 30,
                'available_compartments' => 28,
            ],
            [
                'name' => 'Giga Locker - Victoria',
                'address' => 'Victoria Station, London SW1V 1JU',
                'latitude' => 51.4952,
                'longitude' => -0.1439,
                'status' => 'available',
                'total_compartments' => 20,
                'available_compartments' => 5,
            ],
            [
                'name' => 'Giga Locker - King\'s Cross',
                'address' => 'Euston Rd., London N1 9AL',
                'latitude' => 51.5320,
                'longitude' => -0.1233,
                'status' => 'maintenance',
                'total_compartments' => 25,
                'available_compartments' => 0,
            ],
        ];

        foreach ($lockers as $locker) {
            Locker::create($locker);
        }
    }
}
