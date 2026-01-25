<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryStop extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_id',
        'address',
        'lat',
        'lng',
        'stop_order',
        'status',
        'arrived_at',
        'departed_at',
        'type',
        'instructions',
    ];

    protected $casts = [
        'arrived_at' => 'datetime',
        'departed_at' => 'datetime',
    ];

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }
}
