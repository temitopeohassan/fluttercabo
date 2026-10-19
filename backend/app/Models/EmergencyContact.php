<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmergencyContact extends Model
{
    protected $fillable = ['name', 'phone', 'relationship', 'share_trips_automatically'];

    protected function casts(): array
    {
        return ['share_trips_automatically' => 'boolean'];
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }
}
