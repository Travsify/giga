<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Currency extends Model
{
    protected $fillable = [
        'code',
        'symbol',
        'rate_to_naira',
        'is_active',
    ];

    protected $casts = [
        'rate_to_naira' => 'decimal:4',
        'is_active' => 'boolean',
    ];
}
