<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TourSlot extends Model
{
    protected $fillable = ['starts_at', 'capacity', 'booked', 'guide_driver_id'];

    protected $appends = ['remaining'];

    protected function casts(): array
    {
        return ['starts_at' => 'datetime', 'capacity' => 'integer', 'booked' => 'integer'];
    }

    public function getRemainingAttribute(): int
    {
        return max(0, $this->capacity - $this->booked);
    }

    public function tour(): BelongsTo
    {
        return $this->belongsTo(Tour::class);
    }

    public function guide(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'guide_driver_id');
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(TourBooking::class);
    }
}
