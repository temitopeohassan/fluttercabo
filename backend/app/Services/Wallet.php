<?php

namespace App\Services;

use App\Models\Driver;
use App\Models\Rider;
use App\Models\Transaction;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Validation\ValidationException;

/** Records money movements and keeps rider and driver balances in step. */
class Wallet
{
    public static function record(Model $owner, string $type, string $direction, int $amount, string $method, string $description, ?Model $subject = null, array $meta = []): Transaction
    {
        return Transaction::create([
            'owner_type' => $owner->getMorphClass(),
            'owner_id' => $owner->getKey(),
            'subject_type' => $subject?->getMorphClass(),
            'subject_id' => $subject?->getKey(),
            'type' => $type,
            'direction' => $direction,
            'amount' => $amount,
            'method' => $method,
            'description' => $description,
            'meta' => $meta ?: null,
        ]);
    }

    /** Takes a payment from the rider by the chosen method. */
    public static function charge(Rider $rider, int $amount, string $method, string $description, ?Model $subject = null): Transaction
    {
        if ($method === 'wallet') {
            $rider->refresh();
            if ($rider->wallet_balance < $amount) {
                throw ValidationException::withMessages(['payment_method' => 'Your Cabo wallet balance is too low. Top up or choose another method.']);
            }
            $rider->decrement('wallet_balance', $amount);

            return self::record($rider, 'wallet_payment', 'debit', $amount, 'wallet', $description, $subject);
        }

        return self::record($rider, 'charge', 'debit', $amount, $method, $description, $subject);
    }

    /** Refunds go back to the wallet for wallet payments and to the original method otherwise. */
    public static function refund(Rider $rider, int $amount, string $method, string $description, ?Model $subject = null): ?Transaction
    {
        if ($amount <= 0) {
            return null;
        }
        if ($method === 'wallet') {
            $rider->increment('wallet_balance', $amount);
        }

        return self::record($rider, 'refund', 'credit', $amount, $method, $description, $subject);
    }

    public static function creditDriver(Driver $driver, int $amount, string $type, string $description, ?Model $subject = null): Transaction
    {
        $driver->increment('earnings_balance', $amount);

        return self::record($driver, $type, 'credit', $amount, 'system', $description, $subject);
    }
}
