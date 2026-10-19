<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Setting extends Model
{
    protected $fillable = ['key', 'value', 'label', 'group'];

    public static function read(string $key, mixed $default = null): mixed
    {
        $all = Cache::rememberForever('cabo.settings', fn () => static::pluck('value', 'key')->all());

        return $all[$key] ?? $default;
    }

    protected static function booted(): void
    {
        static::saved(fn () => Cache::forget('cabo.settings'));
        static::deleted(fn () => Cache::forget('cabo.settings'));
    }
}
