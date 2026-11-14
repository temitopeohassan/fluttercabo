<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Services\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class EarningsController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        $driver = $request->user();
        $period = $request->validate(['period' => 'nullable|in:today,week,month'])['period'] ?? 'week';
        $from = match ($period) {
            'today' => today(),
            'month' => now()->startOfMonth(),
            default => now()->startOfWeek(),
        };

        $trips = $driver->trips()->where('status', 'completed')->where('completed_at', '>=', $from);
        $byDay = (clone $trips)->get(['completed_at', 'driver_earnings', 'tip', 'duration_minutes'])
            ->groupBy(fn ($t) => $t->completed_at->toDateString())
            ->map(fn ($day, $date) => ['date' => $date, 'trips' => $day->count(), 'earnings' => (int) $day->sum('driver_earnings')])
            ->values();

        return response()->json(['data' => [
            'period' => $period,
            'from' => $from->toDateString(),
            'trips' => (clone $trips)->count(),
            'earnings' => (int) (clone $trips)->sum('driver_earnings'),
            'tips' => (int) (clone $trips)->sum('tip'),
            'fares' => (int) (clone $trips)->sum('fare_total'),
            'commission' => (int) (clone $trips)->sum('commission'),
            'online_minutes' => (int) (clone $trips)->sum('duration_minutes'),
            'by_day' => $byDay,
            'balance' => $driver->earnings_balance,
            'cash_commission_owed' => $driver->cash_commission_owed,
            'cash_debt_limit' => (int) Setting::read('cash_debt_limit', 20000),
            'next_weekly_payout' => now()->next(Setting::read('weekly_payout_day', 'Tuesday'))->toDateString(),
        ]]);
    }

    public function transactions(Request $request): JsonResponse
    {
        return response()->json($request->user()->transactions()->latest()->paginate(30));
    }

    public function payouts(Request $request): JsonResponse
    {
        return response()->json($request->user()->payouts()->latest()->paginate(20));
    }

    /** Instant cash-out of the earnings balance, less commission owed on cash trips and the fee. */
    public function cashOut(Request $request): JsonResponse
    {
        $driver = $request->user();
        $data = $request->validate(['amount' => 'required|integer|min:'.(int) Setting::read('minimum_cashout', 5000)]);
        if (! $driver->bank_account_number) {
            throw ValidationException::withMessages(['amount' => 'Add your bank details first.']);
        }

        $payout = DB::transaction(function () use ($driver, $data) {
            $driver = $driver->newQuery()->lockForUpdate()->find($driver->id);
            $settled = min($driver->cash_commission_owed, $driver->earnings_balance);
            $available = $driver->earnings_balance - $settled;
            if ($data['amount'] > $available) {
                throw ValidationException::withMessages(['amount' => 'You can cash out up to ₦'.number_format($available).'.']);
            }

            $fee = (int) ceil($data['amount'] * (float) Setting::read('instant_cashout_fee_percent', 1.5) / 100);
            if ($settled > 0) {
                Wallet::record($driver, 'cash_settlement', 'debit', $settled, 'system', 'Cash commission settled from earnings');
            }
            $driver->update([
                'earnings_balance' => $driver->earnings_balance - $settled - $data['amount'],
                'cash_commission_owed' => $driver->cash_commission_owed - $settled,
            ]);
            $payout = $driver->payouts()->create([
                'type' => 'instant', 'amount' => $data['amount'] - $fee, 'fee' => $fee,
                'bank_name' => $driver->bank_name, 'bank_account_number' => $driver->bank_account_number, 'status' => 'pending',
            ]);
            Wallet::record($driver, 'payout', 'debit', $data['amount'], 'bank_transfer', "Instant cash-out {$payout->reference}", $payout, ['fee' => $fee]);

            return $payout;
        });

        return response()->json(['data' => $payout, 'balance' => $driver->fresh()->earnings_balance], 201);
    }

    /** Ratings, acceptance and cancellation for the Host app's performance screens. */
    public function performance(Request $request): JsonResponse
    {
        $driver = $request->user();
        $rated = $driver->trips()->whereNotNull('driver_rating');
        $counts = (clone $rated)->selectRaw('driver_rating as stars, count(*) as total')->groupBy('driver_rating')->pluck('total', 'stars');

        return response()->json(['data' => [
            'rating' => $driver->rating,
            'ratings_count' => (int) $counts->sum(),
            'rating_breakdown' => collect([5, 4, 3, 2, 1])->mapWithKeys(fn ($s) => [$s => (int) ($counts[$s] ?? 0)]),
            'recent_feedback' => (clone $rated)->whereNotNull('driver_feedback')->latest('completed_at')->limit(10)
                ->get(['id', 'reference', 'driver_rating', 'driver_feedback', 'completed_at']),
            'acceptance_rate' => $driver->acceptance_rate,
            'cancellation_rate' => $driver->cancellation_rate,
            'completed_trips' => $driver->trips()->where('status', 'completed')->count(),
            'completed_trips_30_days' => $driver->trips()->where('status', 'completed')->where('completed_at', '>=', now()->subDays(30))->count(),
            'tier' => $driver->tier,
            'is_tour_guide' => $driver->is_tour_guide,
            'training_completed' => $driver->training_completed,
            'member_since' => $driver->approved_at ?? $driver->created_at,
        ]]);
    }
}
