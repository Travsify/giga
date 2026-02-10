<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBid extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_id',
        'rider_id',
        'bid_amount',
        'estimated_pickup_time',
        'status',
        'notes',
    ];

    protected $casts = [
        'bid_amount' => 'decimal:2',
    ];

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }
}
