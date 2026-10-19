<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverDocument extends Model
{
    public const TYPES = [
        'drivers_licence' => "Driver's licence",
        'national_id' => 'National ID (NIN)',
        'proof_of_address' => 'Proof of address',
        'lasdri_card' => 'LASDRI card',
        'state_permit' => 'State permit',
        'vehicle_licence' => 'Vehicle licence',
        'roadworthiness' => 'Roadworthiness certificate',
        'insurance' => 'Insurance certificate',
        'vehicle_photo' => 'Vehicle photo',
        'selfie' => 'Selfie',
    ];

    protected $fillable = ['vehicle_id', 'type', 'label', 'file_path', 'status', 'rejection_reason', 'expires_at', 'reviewed_by', 'reviewed_at'];

    protected function casts(): array
    {
        return ['expires_at' => 'date', 'reviewed_at' => 'datetime'];
    }

    public static function label(string $type): string
    {
        return self::TYPES[$type] ?? $type;
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->endOfDay()->isPast();
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'reviewed_by');
    }
}
