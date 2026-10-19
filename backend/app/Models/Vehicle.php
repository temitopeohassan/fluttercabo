<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vehicle extends Model
{
    protected $fillable = ['make', 'model', 'year', 'colour', 'plate_number', 'seats', 'ride_types', 'wheelchair_accessible', 'status', 'is_active'];

    protected function casts(): array
    {
        return ['ride_types' => 'array', 'wheelchair_accessible' => 'boolean', 'is_active' => 'boolean'];
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(DriverDocument::class);
    }

    public function getDescriptionAttribute(): string
    {
        return "{$this->colour} {$this->make} {$this->model} {$this->year}";
    }
}
