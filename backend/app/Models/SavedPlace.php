<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SavedPlace extends Model
{
    protected $fillable = ['label', 'address', 'lat', 'lng'];

    protected function casts(): array
    {
        return ['lat' => 'float', 'lng' => 'float'];
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }
}
