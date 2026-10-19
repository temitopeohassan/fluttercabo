<?php

namespace App\Models;

use App\Models\Concerns\HasReference;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Trip extends Model
{
    use HasReference;

    public const REFERENCE_PREFIX = 'CB';

    public const ACTIVE_STATUSES = ['requested', 'accepted', 'arrived', 'in_progress'];

    protected $guarded = ['id'];

    protected $hidden = ['declined_driver_ids'];

    protected function casts(): array
    {
        return [
            'stops' => 'array',
            'declined_driver_ids' => 'array',
            'pickup_lat' => 'float', 'pickup_lng' => 'float',
            'dropoff_lat' => 'float', 'dropoff_lng' => 'float',
            'distance_km' => 'float',
            'surge_multiplier' => 'float',
            'scheduled_at' => 'datetime',
            'accepted_at' => 'datetime',
            'arrived_at' => 'datetime',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'cancelled_at' => 'datetime',
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

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function rideType(): BelongsTo
    {
        return $this->belongsTo(RideType::class);
    }

    public function promoCode(): BelongsTo
    {
        return $this->belongsTo(PromoCode::class);
    }

    public function transactions(): MorphMany
    {
        return $this->morphMany(Transaction::class, 'subject');
    }

    public function isActive(): bool
    {
        return in_array($this->status, self::ACTIVE_STATUSES, true);
    }
}
