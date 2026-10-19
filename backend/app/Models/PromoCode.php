<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PromoCode extends Model
{
    protected $fillable = ['code', 'description', 'discount_type', 'value', 'max_discount', 'applies_to', 'first_booking_only', 'usage_limit', 'used_count', 'starts_at', 'ends_at', 'is_active'];

    protected function casts(): array
    {
        return [
            'first_booking_only' => 'boolean', 'is_active' => 'boolean',
            'starts_at' => 'datetime', 'ends_at' => 'datetime',
            'value' => 'integer', 'max_discount' => 'integer',
        ];
    }

    /** Why this code cannot be used, or null when it can. */
    public function rejectionReason(string $service, ?Rider $rider = null): ?string
    {
        if (! $this->is_active) {
            return 'This code is no longer active.';
        }
        if ($this->starts_at && $this->starts_at->isFuture()) {
            return 'This code is not active yet.';
        }
        if ($this->ends_at && $this->ends_at->isPast()) {
            return 'This code has expired.';
        }
        if ($this->usage_limit !== null && $this->used_count >= $this->usage_limit) {
            return 'This code has been fully redeemed.';
        }
        if ($this->applies_to !== 'all' && $this->applies_to !== $service) {
            return 'This code only applies to '.$this->applies_to.' bookings.';
        }
        if ($this->first_booking_only && $rider && ($rider->trips()->where('status', 'completed')->exists() || $rider->tourBookings()->exists() || $rider->shuttleBookings()->exists())) {
            return 'This code is for your first booking only.';
        }

        return null;
    }

    public function discountFor(int $amount): int
    {
        $discount = $this->discount_type === 'percent'
            ? (int) round($amount * $this->value / 100)
            : $this->value;

        if ($this->max_discount !== null) {
            $discount = min($discount, $this->max_discount);
        }

        return min($discount, $amount);
    }
}
