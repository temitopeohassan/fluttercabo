<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class SosAlert extends Model
{
    protected $guarded = ['id'];

    protected function casts(): array
    {
        return ['lat' => 'float', 'lng' => 'float', 'acknowledged_at' => 'datetime', 'resolved_at' => 'datetime'];
    }

    public function raisedBy(): MorphTo
    {
        return $this->morphTo();
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function handler(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'handled_by');
    }
}
