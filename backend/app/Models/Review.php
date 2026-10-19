<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    protected $fillable = ['rider_id', 'tour_id', 'tour_booking_id', 'rating', 'comment', 'highlights', 'is_visible'];

    protected function casts(): array
    {
        return ['highlights' => 'array', 'is_visible' => 'boolean'];
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }

    public function tour(): BelongsTo
    {
        return $this->belongsTo(Tour::class);
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(TourBooking::class, 'tour_booking_id');
    }
}
