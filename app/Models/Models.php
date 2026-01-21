<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Delivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id', 'rider_id', 'parcel_type', 'description',
        'pickup_address', 'pickup_lat', 'pickup_lng',
        'dropoff_address', 'dropoff_lat', 'dropoff_lng',
        'fare', 'status', 'assigned_at', 'picked_up_at', 'delivered_at'
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }
}

class Rider extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'logistics_company_id', 'license_number',
        'vehicle_type', 'vehicle_plate_number', 'is_online',
        'current_lat', 'current_lng'
    ];

    protected $casts = [
        'is_online' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function logisticsCompany()
    {
        return $this->belongsTo(LogisticsCompany::class);
    }

    public function deliveries()
    {
        return $this->hasMany(Delivery::class);
    }
}

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'balance', 'currency'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'wallet_id', 'delivery_id', 'amount', 'type',
        'description', 'reference', 'status'
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

class LogisticsCompany extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'name', 'registration_number', 'address',
        'contact_phone', 'logo_url', 'is_verified'
    ];

    protected $casts = [
        'is_verified' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function riders()
    {
        return $this->hasMany(Rider::class);
    }
}
