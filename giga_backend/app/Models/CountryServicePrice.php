<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CountryServicePrice extends Model
{
    protected $fillable = [
        'country_id',
        'service_id',
        'base_price',
        'price_per_km',
        'price_per_min',
        'minimum_fare',
        'commission_percentage',
        'is_active',
    ];

    protected $casts = [
        'base_price' => 'decimal:2',
        'price_per_km' => 'decimal:2',
        'price_per_min' => 'decimal:2',
        'minimum_fare' => 'decimal:2',
        'commission_percentage' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function country()
    {
        return $this->belongsTo(Country::class);
    }

    public function service()
    {
        return $this->belongsTo(Service::class);
    }
}
