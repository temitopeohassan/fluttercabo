<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class SupportMessage extends Model
{
    protected $fillable = ['sender_type', 'sender_id', 'body'];

    protected $appends = ['sender_role'];

    protected $hidden = ['sender_type'];

    public function ticket(): BelongsTo
    {
        return $this->belongsTo(SupportTicket::class, 'support_ticket_id');
    }

    public function sender(): MorphTo
    {
        return $this->morphTo();
    }

    public function getSenderRoleAttribute(): string
    {
        return match ($this->sender_type) {
            'admin' => 'support',
            'driver' => 'driver',
            default => 'rider',
        };
    }
}
