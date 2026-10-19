<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Attraction extends Model
{
    protected $fillable = ['name', 'slug', 'category', 'area', 'description', 'address', 'lat', 'lng', 'opening_hours', 'entry_fee', 'visitor_tips', 'safety_notes', 'image_url', 'rating', 'reviews_count', 'is_published', 'last_reviewed_on'];

    protected $appends = ['image'];

    protected function casts(): array
    {
        return [
            'visitor_tips' => 'array', 'lat' => 'float', 'lng' => 'float', 'rating' => 'float',
            'entry_fee' => 'integer', 'is_published' => 'boolean', 'last_reviewed_on' => 'date',
        ];
    }

    public function wishlistedBy(): MorphMany
    {
        return $this->morphMany(WishlistItem::class, 'item');
    }

    /** Absolute URL for image_url, which may be stored as a path under public/. */
    public function getImageAttribute(): ?string
    {
        if (! $this->image_url) {
            return null;
        }

        return str_starts_with($this->image_url, 'http') ? $this->image_url : url($this->image_url);
    }
}
