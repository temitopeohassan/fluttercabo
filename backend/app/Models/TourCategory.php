<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TourCategory extends Model
{
    protected $fillable = ['name', 'slug', 'icon', 'sort_order'];

    public function tours(): HasMany
    {
        return $this->hasMany(Tour::class);
    }
}
