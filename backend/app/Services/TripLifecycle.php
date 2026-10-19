<?php

namespace App\Services;

use App\Models\Driver;
use App\Models\Setting;
use App\Models\Trip;
use Illuminate\Support\Facades\DB;

/** Money side of finishing and cancelling rides. */
class TripLifecycle
{
    public function __construct(private FareCalculator $fares) {}

    /** Waiting time beyond the free minutes between arrival and start. */
    public function waitingFee(Trip $trip): int
    {
        if (! $trip->arrived_at || ! $trip->started_at) {
            return 0;
        }
        $free = (int) Setting::read('free_waiting_minutes', 5);
        $waited = (int) floor($trip->arrived_at->diffInMinutes($trip->started_at));

        return max(0, $waited - $free) * (int) Setting::read('waiting_fee_per_minute', 50);
    }

    public function complete(Trip $trip): Trip
    {
        return DB::transaction(function () use ($trip) {
            $waiting = $this->waitingFee($trip);
            $fare = $trip->fare_total + $waiting;
            $split = $this->fares->split($fare);

            $trip->fill([
                'status' => 'completed',
                'completed_at' => now(),
                'fare_time' => $trip->fare_time + $waiting,
                'fare_total' => $fare,
                'commission' => $split['commission'],
                'driver_earnings' => $split['driver_earnings'],
            ]);

            if ($trip->payment_method === 'cash') {
                // Collected by the driver; paid once they confirm the cash.
                $trip->payment_status = 'pending';
            } else {
                Wallet::charge($trip->rider, $fare, $trip->payment_method, "Ride {$trip->reference}", $trip);
                Wallet::creditDriver($trip->driver, $split['driver_earnings'], 'driver_earning', "Earnings {$trip->reference}", $trip);
                $trip->payment_status = 'paid';
            }
            $trip->save();

            if ($trip->promo_code_id) {
                $trip->promoCode()->increment('used_count');
            }
            $trip->rider->increment('loyalty_points', (int) floor($fare / 100));

            return $trip;
        });
    }

    /** Driver confirms the rider paid in cash; commission becomes owed to Cabo. */
    public function collectCash(Trip $trip): Trip
    {
        return DB::transaction(function () use ($trip) {
            $trip->update(['payment_status' => 'paid']);
            Wallet::record($trip->rider, 'charge', 'debit', $trip->fare_total, 'cash', "Ride {$trip->reference}", $trip);
            Wallet::record($trip->driver, 'commission', 'debit', $trip->commission, 'cash', "Commission owed on cash ride {$trip->reference}", $trip);
            $trip->driver->increment('cash_commission_owed', $trip->commission);

            return $trip;
        });
    }

    /** Rider cancellation fee: free before acceptance and inside the grace window. */
    public function riderCancellationFee(Trip $trip): int
    {
        if (! $trip->accepted_at) {
            return 0;
        }
        $grace = (int) Setting::read('free_cancellation_minutes', 2);
        if ($trip->status === 'accepted' && $trip->accepted_at->diffInMinutes(now()) < $grace) {
            return 0;
        }

        return (int) Setting::read('rider_cancellation_fee', 500);
    }

    public function cancel(Trip $trip, string $by, ?string $reason): Trip
    {
        return DB::transaction(function () use ($trip, $by, $reason) {
            $fee = $by === 'rider' ? $this->riderCancellationFee($trip) : 0;
            $trip->update([
                'status' => $by === 'driver' && $trip->status === 'arrived' && $reason === 'no_show' ? 'no_show' : 'cancelled',
                'cancelled_by' => $by,
                'cancellation_reason' => $reason,
                'cancellation_fee' => $fee,
                'cancelled_at' => now(),
                'payment_status' => $fee > 0 ? 'paid' : 'refunded',
            ]);

            if ($fee > 0) {
                $method = $trip->payment_method === 'cash' ? 'card' : $trip->payment_method;
                Wallet::charge($trip->rider, $fee, $method, "Cancellation fee {$trip->reference}", $trip);
                if ($trip->driver) {
                    Wallet::creditDriver($trip->driver, $fee, 'driver_earning', "Cancellation fee {$trip->reference}", $trip);
                }
            }

            if ($by === 'driver' && $trip->driver) {
                $this->refreshDriverRates($trip->driver_id);
            }

            return $trip;
        });
    }

    public function refreshDriverRates(int $driverId): void
    {
        $total = Trip::where('driver_id', $driverId)->whereIn('status', ['completed', 'cancelled', 'no_show'])->count();
        if ($total === 0) {
            return;
        }
        $cancelled = Trip::where('driver_id', $driverId)->where('cancelled_by', 'driver')->count();
        Driver::whereKey($driverId)->update(['cancellation_rate' => round($cancelled / $total * 100, 1)]);
    }
}
