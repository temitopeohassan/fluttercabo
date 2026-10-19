<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Partner extends Model
{
    protected $fillable = ['name', 'type', 'contact_name', 'email', 'phone', 'cac_number', 'status', 'commission_rate', 'bank_name', 'bank_account_number', 'bank_account_name'];

    protected function casts(): array
    {
        return ['commission_rate' => 'float'];
    }

    public function tours(): HasMany
    {
        return $this->hasMany(Tour::class);
    }
}
