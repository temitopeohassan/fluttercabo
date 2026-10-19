<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaitlistSignup extends Model
{
    protected $fillable = ['name', 'email', 'source', 'ip_address', 'invited_at'];

    protected function casts(): array
    {
        return ['invited_at' => 'datetime'];
    }
}
