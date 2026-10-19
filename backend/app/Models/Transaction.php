<?php

namespace App\Models;

use App\Models\Concerns\HasReference;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Transaction extends Model
{
    use HasReference;

    public const REFERENCE_PREFIX = 'TX';

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return ['meta' => 'array', 'amount' => 'integer'];
    }

    public function owner(): MorphTo
    {
        return $this->morphTo();
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }
}
