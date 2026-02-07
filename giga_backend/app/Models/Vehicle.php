<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    use HasFactory;

    protected $fillable = [
        'rider_id',
        'vehicle_type',
        'vehicle_plate_number',
        'make',
        'model',
        'color',
        'year',
        'is_verified',
        'verification_status',
        'rejection_reason',
        'verification_errors',
        'vehicle_front_path',
        'vehicle_side_path',
        'vehicle_interior_path',
        'vehicle_license_path',
        'vehicle_registration_path',
        'insurance_certificate_path',
    ];

    protected $casts = [
        'is_verified' => 'boolean',
        'verification_errors' => 'array',
    ];

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }
}
