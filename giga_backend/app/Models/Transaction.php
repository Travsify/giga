<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'wallet_id',
        'delivery_id',
        'amount',
        'type',
        'description',
        'reference',
        'status',
        'currency',
        'metadata',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
    ];

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }
}
