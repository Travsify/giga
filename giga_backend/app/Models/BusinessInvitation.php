<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BusinessInvitation extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'email',
        'role',
        'token',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function business()
    {
        return $this->belongsTo(LogisticsCompany::class, 'business_id');
    }
}
