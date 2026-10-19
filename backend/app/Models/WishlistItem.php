<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class WishlistItem extends Model
{
    protected $fillable = ['item_type', 'item_id'];

    public function rider(): BelongsTo
    {
        return $this->belongsTo(Rider::class);
    }

    public function item(): MorphTo
    {
        return $this->morphTo();
    }
}
