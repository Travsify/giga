<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Delivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'rider_id',
        'parcel_type',
        'description',
        'pickup_address',
        'pickup_lat',
        'pickup_lng',
        'dropoff_address',
        'dropoff_lat',
        'dropoff_lng',
        'fare',
        'status',
        'assigned_at',
        'picked_up_at',
        'delivered_at',
        'proof_of_delivery_url',
        'contactless_delivery',
        'security_code',
        'locker_id',
        'locker_code',
        'service_tier',
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
        'fare' => 'decimal:2',
        'contactless_delivery' => 'boolean',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }

    public function stops()
    {
        return $this->hasMany(DeliveryStop::class)->orderBy('stop_order');
    }
}
