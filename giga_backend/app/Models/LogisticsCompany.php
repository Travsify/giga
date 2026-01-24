<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LogisticsCompany extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'company_type',
        'business_email',
        'registration_number',
        'vat_number',
        'address',
        'website',
        'billing_details',
        'contact_phone',
        'logo_url',
        'is_verified',
        'credit_limit',
        'outstanding_balance'
    ];

    protected $casts = [
        'is_verified' => 'boolean',
        'billing_details' => 'json',
        'credit_limit' => 'decimal:2',
        'outstanding_balance' => 'decimal:2'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function riders()
    {
        return $this->hasMany(Rider::class);
    }

    public function members()
    {
        return $this->hasMany(User::class, 'business_id');
    }

    public function invitations()
    {
        return $this->hasMany(BusinessInvitation::class, 'business_id');
    }
}
