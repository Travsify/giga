<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ApiKey extends Model
{
    use HasFactory;

    protected $fillable = [
        'logistics_company_id',
        'name',
        'key',
        'prefix',
        'last_used_at',
        'is_active'
    ];

    protected $casts = [
        'last_used_at' => 'datetime',
        'is_active' => 'boolean'
    ];

    public function logisticsCompany()
    {
        return $this->belongsTo(LogisticsCompany::class);
    }
}
