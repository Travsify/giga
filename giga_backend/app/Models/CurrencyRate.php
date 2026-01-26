<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CurrencyRate extends Model
{
    use HasFactory;

    protected $fillable = [
        'currency_code',
        'symbol',
        'rate_to_gbp',
        'is_active',
        'is_base'
    ];

    protected $casts = [
        'rate_to_gbp' => 'decimal:4',
        'is_active' => 'boolean',
        'is_base' => 'boolean',
    ];
}
