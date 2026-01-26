<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GiftCard extends Model
{
    protected $fillable = [
        'code',
        'amount',
        'currency_code',
        'current_uses',
        'max_uses',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'current_uses' => 'integer',
        'max_uses' => 'integer',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];
}
