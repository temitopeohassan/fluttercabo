<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Tour extends Model
{
    protected $fillable = [
        'partner_id', 'tour_category_id', 'title', 'slug', 'description', 'area', 'meeting_point',
        'meeting_lat', 'meeting_lng', 'duration_minutes', 'price', 'min_group_size', 'max_group_size',
        'languages', 'itinerary', 'inclusions', 'exclusions', 'addons', 'cancellation_policy', 'image_url',
        'wheelchair_accessible', 'rating', 'reviews_count', 'is_featured', 'is_published',
    ];

    protected $appends = ['image'];

    protected function casts(): array
    {
        return [
            'languages' => 'array', 'itinerary' => 'array', 'inclusions' => 'array',
            'exclusions' => 'array', 'addons' => 'array',
            'meeting_lat' => 'float', 'meeting_lng' => 'float',
            'price' => 'integer', 'rating' => 'float',
            'wheelchair_accessible' => 'boolean', 'is_featured' => 'boolean', 'is_published' => 'boolean',
        ];
    }

    public function partner(): BelongsTo
    {
        return $this->belongsTo(Partner::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(TourCategory::class, 'tour_category_id');
    }

    public function slots(): HasMany
    {
        return $this->hasMany(TourSlot::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(TourBooking::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function wishlistedBy(): MorphMany
    {
        return $this->morphMany(WishlistItem::class, 'item');
    }

    public function addon(string $code): ?array
    {
        return collect($this->addons ?? [])->firstWhere('code', $code);
    }

    public function refreshRating(): void
    {
        $visible = $this->reviews()->where('is_visible', true);
        $this->update([
            'rating' => round((float) $visible->avg('rating'), 2) ?: null,
            'reviews_count' => $visible->count(),
        ]);
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
