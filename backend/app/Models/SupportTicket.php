<?php

namespace App\Models;

use App\Models\Concerns\HasReference;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class SupportTicket extends Model
{
    use HasReference;

    public const REFERENCE_PREFIX = 'ST';

    public const CATEGORIES = ['lost_item', 'overcharge', 'fare_dispute', 'refund', 'driver_behaviour', 'rider_behaviour', 'vehicle_damage', 'accident', 'payout', 'account', 'other'];

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return ['resolved_at' => 'datetime'];
    }

    public function requester(): MorphTo
    {
        return $this->morphTo();
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(SupportMessage::class);
    }

    public function assignee(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'assigned_admin_id');
    }
}
