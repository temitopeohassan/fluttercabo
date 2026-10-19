<?php

namespace App\Models\Concerns;

use Illuminate\Support\Str;

/**
 * Gives a model a human-readable reference such as CB-7K2Q9M, set on create.
 * The using class defines REFERENCE_PREFIX.
 */
trait HasReference
{
    protected static function bootHasReference(): void
    {
        static::creating(function ($model) {
            if (empty($model->reference)) {
                do {
                    $ref = static::REFERENCE_PREFIX.'-'.strtoupper(Str::random(6));
                } while (static::where('reference', $ref)->exists());
                $model->reference = $ref;
            }
        });
    }
}
