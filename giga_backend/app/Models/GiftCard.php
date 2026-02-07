<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GiftCard extends Model
{
    protected $fillable = [
        'user_id',
        'code',
        'amount',
        'balance',
        'currency_code',
        'is_active',
        'expires_at',
        'redeemed_at',
        'recipient_email' // Optional
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'expires_at' => 'datetime',
        'redeemed_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
