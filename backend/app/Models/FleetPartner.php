<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FleetPartner extends Model
{
    protected $fillable = ['name', 'area', 'contact_name', 'phone', 'email', 'is_active'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }

    public function drivers(): HasMany
    {
        return $this->hasMany(Driver::class);
    }
}
