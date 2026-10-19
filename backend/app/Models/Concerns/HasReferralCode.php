<?php

namespace App\Models\Concerns;

use Illuminate\Support\Str;

trait HasReferralCode
{
    protected static function bootHasReferralCode(): void
    {
        static::creating(function ($model) {
            if (empty($model->referral_code)) {
                do {
                    $code = strtoupper(Str::random(8));
                } while (static::withTrashed()->where('referral_code', $code)->exists());
                $model->referral_code = $code;
            }
        });
    }
}
