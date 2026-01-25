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

    public function servicePrices()
    {
        return $this->hasMany(CountryServicePrice::class);
    }

    public function services()
    {
        return $this->belongsToMany(Service::class, 'country_service_prices')
            ->withPivot([
                'base_price',
                'price_per_km',
                'price_per_min',
                'minimum_fare',
                'commission_percentage',
                'is_active',
            ])
            ->withTimestamps();
    }
}
