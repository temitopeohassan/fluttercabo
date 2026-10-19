<?php

namespace App\Models;

use App\Models\Concerns\HasReferralCode;
use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Sanctum\HasApiTokens;

/** Signs in to the driver app with a one-time code and a Sanctum token; there is no password. */
class Driver extends Model implements AuthenticatableContract
{
    use Authenticatable, HasApiTokens, HasReferralCode, SoftDeletes;

    /** Documents a driver must have approved before going online. */
    public const REQUIRED_DOCUMENTS = ['drivers_licence', 'national_id', 'lasdri_card', 'vehicle_licence', 'roadworthiness', 'insurance'];

    protected $fillable = [
        'first_name', 'last_name', 'email', 'phone', 'photo_url', 'date_of_birth', 'address', 'languages',
        'driver_type', 'fleet_partner_id', 'status', 'status_reason', 'tier', 'is_tour_guide',
        'training_completed', 'background_check_consent', 'inspection_at', 'inspection_location',
        'is_online', 'current_lat', 'current_lng', 'location_updated_at', 'preferences', 'rating',
        'acceptance_rate', 'cancellation_rate', 'bank_name', 'bank_account_number', 'bank_account_name',
        'earnings_balance', 'cash_commission_owed', 'referral_code', 'approved_at',
    ];

    protected $appends = ['name'];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'languages' => 'array',
            'preferences' => 'array',
            'is_tour_guide' => 'boolean',
            'training_completed' => 'boolean',
            'background_check_consent' => 'boolean',
            'is_online' => 'boolean',
            'inspection_at' => 'datetime',
            'location_updated_at' => 'datetime',
            'approved_at' => 'datetime',
            'current_lat' => 'float',
            'current_lng' => 'float',
            'rating' => 'float',
            'acceptance_rate' => 'float',
            'cancellation_rate' => 'float',
            'earnings_balance' => 'integer',
            'cash_commission_owed' => 'integer',
        ];
    }

    public function getNameAttribute(): string
    {
        return trim("{$this->first_name} {$this->last_name}") ?: $this->phone;
    }

    public function fleetPartner(): BelongsTo
    {
        return $this->belongsTo(FleetPartner::class);
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    public function activeVehicle(): HasOne
    {
        return $this->hasOne(Vehicle::class)->where('is_active', true);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(DriverDocument::class);
    }

    public function trips(): HasMany
    {
        return $this->hasMany(Trip::class);
    }

    public function shuttleBookings(): HasMany
    {
        return $this->hasMany(ShuttleBooking::class);
    }

    public function tourSlots(): HasMany
    {
        return $this->hasMany(TourSlot::class, 'guide_driver_id');
    }

    public function payouts(): HasMany
    {
        return $this->hasMany(Payout::class);
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

    /**
     * Reasons the driver may not go online, empty when they can.
     *
     * @return list<string>
     */
    public function onlineBlockers(): array
    {
        $blockers = [];

        if ($this->status !== 'approved') {
            $blockers[] = 'Your account is '.str_replace('_', ' ', $this->status).'.';
        }

        $documents = $this->documents()->get();
        foreach (self::REQUIRED_DOCUMENTS as $type) {
            $doc = $documents->where('type', $type)->sortByDesc('id')->first();
            if (! $doc || $doc->status !== 'approved') {
                $blockers[] = DriverDocument::label($type).' is not approved.';
            } elseif ($doc->isExpired()) {
                $blockers[] = DriverDocument::label($type).' has expired.';
            }
        }

        if (! $this->activeVehicle()->where('status', 'approved')->exists()) {
            $blockers[] = 'You have no approved active vehicle.';
        }

        $limit = (int) Setting::read('cash_debt_limit', 20000);
        if ($this->cash_commission_owed > $limit) {
            $blockers[] = 'Cash commission owed is over the ₦'.number_format($limit).' limit.';
        }

        return $blockers;
    }
}
