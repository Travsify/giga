<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;

class User extends Authenticatable implements FilamentUser
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
        'country_code',
        'currency_code',
        'country_id',
        'is_country_admin',
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
        'is_country_admin' => 'boolean',
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

    public function canAccessPanel(Panel $panel): bool
    {
        // Allow access to superadmins and country admins
        return str_ends_with($this->email, '@giga.com') 
            || $this->role === 'SuperAdmin' 
            || $this->is_country_admin;
    }

    public function country()
    {
        return $this->belongsTo(Country::class);
    }
}
