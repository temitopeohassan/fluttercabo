<?php

namespace App\Models;

use App\Models\Concerns\HasReferralCode;
use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Sanctum\HasApiTokens;

/** Signs in to the rider app with a one-time code and a Sanctum token; there is no password. */
class Rider extends Model implements AuthenticatableContract
{
    use Authenticatable, HasApiTokens, HasReferralCode, SoftDeletes;

    protected $fillable = [
        'first_name', 'last_name', 'email', 'phone', 'photo_url', 'nationality', 'home_currency',
        'traveller_type', 'language', 'accessibility', 'wallet_balance', 'loyalty_points',
        'referral_code', 'referred_by_id', 'status', 'rating', 'last_active_at',
    ];

    protected $appends = ['name'];

    protected function casts(): array
    {
        return [
            'accessibility' => 'array',
            'wallet_balance' => 'integer',
            'loyalty_points' => 'integer',
            'rating' => 'float',
            'last_active_at' => 'datetime',
        ];
    }

    public function getNameAttribute(): string
    {
        return trim("{$this->first_name} {$this->last_name}") ?: ($this->phone ?? $this->email ?? 'Rider');
    }

    public function referredBy(): BelongsTo
    {
        return $this->belongsTo(Rider::class, 'referred_by_id');
    }

    public function emergencyContacts(): HasMany
    {
        return $this->hasMany(EmergencyContact::class);
    }

    public function savedPlaces(): HasMany
    {
        return $this->hasMany(SavedPlace::class);
    }

    public function trips(): HasMany
    {
        return $this->hasMany(Trip::class);
    }

    public function shuttleBookings(): HasMany
    {
        return $this->hasMany(ShuttleBooking::class);
    }

    public function tourBookings(): HasMany
    {
        return $this->hasMany(TourBooking::class);
    }

    public function wishlistItems(): HasMany
    {
        return $this->hasMany(WishlistItem::class);
    }

    public function transactions(): MorphMany
    {
        return $this->morphMany(Transaction::class, 'owner');
    }

    public function supportTickets(): MorphMany
    {
        return $this->morphMany(SupportTicket::class, 'requester');
    }

    public function appNotifications(): MorphMany
    {
        return $this->morphMany(AppNotification::class, 'recipient');
    }
}
