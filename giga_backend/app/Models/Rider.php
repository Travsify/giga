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
        'current_lng'
    ];

    protected $casts = [
        'is_online' => 'boolean',
        'current_lat' => 'double',
        'current_lng' => 'double',
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
