<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BankAccount extends Model
{
    protected $fillable = [
        'rider_id',
        'account_name',
        'account_number',
        'bank_name',
        'bank_code',
        'sort_code',
        'gateway_type',
        'is_active',
    ];

    public function rider()
    {
        return $this->belongsTo(Rider::class);
    }
}
