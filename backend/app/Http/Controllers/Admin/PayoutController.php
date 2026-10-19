<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Payout;
use App\Models\Transaction;
use App\Services\Wallet;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class PayoutController extends Controller
{
    public function index(Request $request): View
    {
        $payouts = Payout::with('driver:id,first_name,last_name', 'processor:id,name')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->type, fn ($q, $t) => $q->where('type', $t))
            ->orderByRaw("case status when 'pending' then 0 when 'processing' then 1 else 2 end")->latest()
            ->paginate(30)->withQueryString();

        $weekly = Driver::where('status', 'approved')->where('earnings_balance', '>', 0)->whereNotNull('bank_account_number')->get();

        return view('admin.payouts.index', [
            'payouts' => $payouts,
            'weeklyDue' => ['drivers' => $weekly->count(), 'amount' => (int) $weekly->sum(fn ($d) => max(0, $d->earnings_balance - $d->cash_commission_owed))],
        ]);
    }

    public function update(Request $request, Payout $payout): RedirectResponse
    {
        $data = $request->validate(['status' => 'required|in:processing,paid,failed']);
        abort_if(in_array($payout->status, ['paid', 'failed'], true), 422, 'This payout is already closed.');

        DB::transaction(function () use ($payout, $data, $request) {
            $payout->update([
                'status' => $data['status'], 'processed_by' => $request->user()->id,
                'paid_at' => $data['status'] === 'paid' ? now() : null,
            ]);
            // A failed transfer goes back into the driver's balance.
            if ($data['status'] === 'failed') {
                $payout->driver->increment('earnings_balance', $payout->amount + $payout->fee);
                Wallet::record($payout->driver, 'refund', 'credit', $payout->amount + $payout->fee, 'system', "Payout {$payout->reference} failed; returned to balance", $payout);
            }
        });

        return back()->with('status', "Payout {$payout->reference} marked ".$data['status'].'.');
    }

    /** Create this week's payouts for every approved driver with a balance. */
    public function runWeekly(Request $request): RedirectResponse
    {
        $count = 0;
        $start = now()->startOfWeek()->subWeek();
        DB::transaction(function () use (&$count, $start, $request) {
            Driver::where('status', 'approved')->where('earnings_balance', '>', 0)->whereNotNull('bank_account_number')->lockForUpdate()->get()
                ->each(function (Driver $driver) use (&$count, $start, $request) {
                    $settled = min($driver->cash_commission_owed, $driver->earnings_balance);
                    $amount = $driver->earnings_balance - $settled;
                    if ($settled > 0) {
                        Wallet::record($driver, 'cash_settlement', 'debit', $settled, 'system', 'Cash commission settled from earnings');
                    }
                    $driver->update(['earnings_balance' => 0, 'cash_commission_owed' => $driver->cash_commission_owed - $settled]);
                    if ($amount <= 0) {
                        return;
                    }
                    $payout = $driver->payouts()->create([
                        'type' => 'weekly', 'amount' => $amount, 'fee' => 0,
                        'period_start' => $start->toDateString(), 'period_end' => $start->copy()->endOfWeek()->toDateString(),
                        'bank_name' => $driver->bank_name, 'bank_account_number' => $driver->bank_account_number,
                        'status' => 'processing', 'processed_by' => $request->user()->id,
                    ]);
                    Wallet::record($driver, 'payout', 'debit', $amount, 'bank_transfer', "Weekly payout {$payout->reference}", $payout);
                    $count++;
                });
        });

        return back()->with('status', "{$count} weekly payouts created and marked processing.");
    }

    public function transactions(Request $request): View
    {
        $transactions = Transaction::with('owner')
            ->when($request->type, fn ($q, $t) => $q->where('type', $t))
            ->when($request->method, fn ($q, $m) => $q->where('method', $m))
            ->when($request->q, fn ($q, $s) => $q->where(fn ($q) => $q->where('reference', 'like', "%$s%")->orWhere('description', 'like', "%$s%")))
            ->latest()->paginate(50)->withQueryString();

        return view('admin.payouts.transactions', compact('transactions'));
    }
}
