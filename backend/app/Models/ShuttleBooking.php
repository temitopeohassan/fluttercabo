<?php

namespace App\Models;

use App\Models\Concerns\HasReference;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShuttleBooking extends Model
{
    use HasReference;

    public const REFERENCE_PREFIX = 'SH';

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return [
            'flight_time' => 'datetime',
            'pickup_at' => 'datetime',
            'driver_assigned_at' => 'datetime',
            'lat' => 'float', 'lng' => 'float',
        ];
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class);
    }

    public function rideType(): BelongsTo
    {
        return $this->belongsTo(RideType::class);
    }
}
