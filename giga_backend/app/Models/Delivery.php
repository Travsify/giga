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
        'escrow_pin',
        'is_escrow',
        'escrow_status',
        'green_choice',
        'service_category',
        'recipient_phone',
        'location_requested',
        'group_id',
        'is_insured',
        'insurance_premium',
        'insured_value',
        'insurance_policy_no',
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
        'fare' => 'decimal:2',
        'contactless_delivery' => 'boolean',
        'is_escrow' => 'boolean',
        'is_insured' => 'boolean',
        'location_requested' => 'boolean',
        'insurance_premium' => 'decimal:2',
        'insured_value' => 'decimal:2',
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

    public function bids()
    {
        return $this->hasMany(DeliveryBid::class);
    }

    public function returnRequest()
    {
        return $this->hasOne(ReturnRequest::class);
    }

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($delivery) {
            if (empty($delivery->security_code)) {
                $delivery->security_code = str_pad(rand(0, 9999), 4, '0', STR_PAD_LEFT);
            }
        });
    }
}
