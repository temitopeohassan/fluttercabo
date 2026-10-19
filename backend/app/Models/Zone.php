<?php

namespace App\Models;

use App\Support\Geo;
use Illuminate\Database\Eloquent\Model;

class Zone extends Model
{
    protected $fillable = ['name', 'center_lat', 'center_lng', 'radius_km', 'surge_multiplier', 'is_service_area', 'is_active'];

    protected function casts(): array
    {
        return [
            'center_lat' => 'float', 'center_lng' => 'float', 'radius_km' => 'float',
            'surge_multiplier' => 'float', 'is_service_area' => 'boolean', 'is_active' => 'boolean',
        ];
    }

    public function contains(float $lat, float $lng): bool
    {
        return Geo::distanceKm($this->center_lat, $this->center_lng, $lat, $lng) <= $this->radius_km;
    }

    /** The active zone a point falls in, nearest centre first. */
    public static function at(float $lat, float $lng): ?self
    {
        return static::where('is_active', true)->get()
            ->filter(fn (Zone $z) => $z->contains($lat, $lng))
            ->sortBy(fn (Zone $z) => Geo::distanceKm($z->center_lat, $z->center_lng, $lat, $lng))
            ->first();
    }
}
