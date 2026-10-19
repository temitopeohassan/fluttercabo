<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class AppNotification extends Model
{
    protected $fillable = ['type', 'title', 'body', 'data', 'read_at'];

    protected $hidden = ['recipient_type', 'recipient_id'];

    protected function casts(): array
    {
        return ['data' => 'array', 'read_at' => 'datetime'];
    }

    public function recipient(): MorphTo
    {
        return $this->morphTo();
    }
}
