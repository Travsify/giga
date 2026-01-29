<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WarehousePackage extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'tracking_number',
        'carrier',
        'weight_kg',
        'description',
        'status',
        'shipping_fee',
        'photo_url',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
