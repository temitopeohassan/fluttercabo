<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RideType extends Model
{
    protected $fillable = ['code', 'name', 'description', 'seats', 'base_fare', 'per_km', 'per_minute', 'minimum_fare', 'sort_order', 'is_active'];

    protected function casts(): array
    {
        return [
            'base_fare' => 'integer', 'per_km' => 'integer', 'per_minute' => 'integer',
            'minimum_fare' => 'integer', 'is_active' => 'boolean',
        ];
    }
}
