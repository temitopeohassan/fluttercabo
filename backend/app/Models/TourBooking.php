<?php

namespace App\Models;

use App\Models\Concerns\HasReference;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class TourBooking extends Model
{
    use HasReference;

    public const REFERENCE_PREFIX = 'TR';

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return ['addons' => 'array', 'checked_in_at' => 'datetime', 'cancelled_at' => 'datetime'];
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }

    public function tour(): BelongsTo
    {
        return $this->belongsTo(Tour::class);
    }

    public function slot(): BelongsTo
    {
        return $this->belongsTo(TourSlot::class, 'tour_slot_id');
    }

    public function rideTrip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'ride_trip_id');
    }

    public function promoCode(): BelongsTo
    {
        return $this->belongsTo(PromoCode::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class);
    }
}
