<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'referral_code',
        'referred_by_id',
        'loyalty_points',
        'uk_phone',
        'home_address',
        'work_address',
        'is_giga_plus',
        'giga_plus_expiry',
        'business_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_giga_plus' => 'boolean',
        'giga_plus_expiry' => 'datetime',
    ];

    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }

    public function deliveries()
    {
        return $this->hasMany(Delivery::class, 'customer_id');
    }

    public function rider()
    {
        return $this->hasOne(Rider::class);
    }

    public function logisticsCompany()
    {
        return $this->hasOne(LogisticsCompany::class);
    }

    public function business()
    {
        return $this->belongsTo(LogisticsCompany::class, 'business_id');
    }

    public function referredBy()
    {
        return $this->belongsTo(User::class, 'referred_by_id');
    }

    public function referrals()
    {
        return $this->hasMany(User::class, 'referred_by_id');
    }
}
