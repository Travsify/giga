<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Locker extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'latitude',
        'longitude',
        'status', // available, full, maintenance
        'total_compartments',
        'available_compartments',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
    ];
}
