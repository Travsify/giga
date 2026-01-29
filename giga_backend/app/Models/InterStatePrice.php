<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InterStatePrice extends Model
{
    use HasFactory;

    protected $fillable = [
        'origin_state',
        'destination_state',
        'base_price',
        'medium_surcharge',
        'large_surcharge',
        'delivery_days',
    ];
}
