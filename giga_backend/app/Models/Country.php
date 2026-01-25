<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Country extends Model
{
    protected $fillable = [
        'name',
        'iso_code',
        'currency_code',
        'currency_symbol',
        'phone_code',
        'payment_gateways',
        'features',
        'is_active',
        'is_default',
    ];

    protected $casts = [
        'payment_gateways' => 'array',
        'features' => 'array',
        'is_active' => 'boolean',
        'is_default' => 'boolean',
    ];
}
