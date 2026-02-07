<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rider extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'logistics_company_id',
        'license_number',
        'vehicle_type',
        'vehicle_plate_number',
        'is_online',
        'current_lat',
        'current_lng',
        'has_vehicle',
        'vehicle_verified',
        'driver_license_path',
        'vehicle_license_path',
        'vehicle_registration_path',
        'insurance_certificate_path',
        'verification_status',
        // New verification fields
        'country',
        'passport_photo_path',
        'nin_path',
        'intl_passport_path',
        'dvla_license_path',
        'brp_path',
        'identity_doc_type',
        'selfie_id_path',
        'rejection_reason',
        'verification_errors',
        'vehicle_front_path',
        'vehicle_side_path',
        'vehicle_interior_path',
    ];

    protected $casts = [
        'is_online' => 'boolean',
        'current_lat' => 'double',
        'current_lng' => 'double',
        'has_vehicle' => 'boolean',
        'vehicle_verified' => 'boolean',
        'verification_errors' => 'array',
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

    public function bankAccounts()
    {
        return $this->hasMany(BankAccount::class);
    }
}
