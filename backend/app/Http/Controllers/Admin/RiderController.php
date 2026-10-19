<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rider;
use App\Services\Wallet;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class RiderController extends Controller
{
    public function index(Request $request): View
    {
        $riders = Rider::query()
            ->when($request->q, fn ($q, $s) => $q->where(fn ($q) => $q->where('first_name', 'like', "%$s%")->orWhere('last_name', 'like', "%$s%")->orWhere('email', 'like', "%$s%")->orWhere('phone', 'like', "%$s%")))
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->type, fn ($q, $t) => $q->where('traveller_type', $t))
            ->withCount(['trips' => fn ($q) => $q->where('status', 'completed'), 'tourBookings'])
            ->latest()->paginate(25)->withQueryString();

        return view('admin.riders.index', compact('riders'));
    }

    public function show(Rider $rider): View
    {
        $rider->load('emergencyContacts', 'savedPlaces', 'referredBy:id,first_name,last_name');

        return view('admin.riders.show', [
            'rider' => $rider,
            'trips' => $rider->trips()->with('driver:id,first_name,last_name', 'rideType:id,name')->latest()->limit(15)->get(),
            'tourBookings' => $rider->tourBookings()->with('tour:id,title', 'slot:id,starts_at')->latest()->limit(10)->get(),
            'shuttles' => $rider->shuttleBookings()->latest()->limit(5)->get(),
            'transactions' => $rider->transactions()->latest()->limit(15)->get(),
            'tickets' => $rider->supportTickets()->latest()->limit(5)->get(),
        ]);
    }

    public function status(Request $request, Rider $rider): RedirectResponse
    {
        $data = $request->validate(['status' => 'required|in:active,suspended']);
        $rider->update($data);
        if ($data['status'] === 'suspended') {
            $rider->tokens()->delete();
        }

        return back()->with('status', "{$rider->name} is now {$data['status']}.");
    }

    /** Goodwill credit or correction to the rider's wallet. */
    public function credit(Request $request, Rider $rider): RedirectResponse
    {
        $data = $request->validate(['amount' => 'required|integer|min:100|max:200000', 'reason' => 'required|string|max:120']);
        $rider->increment('wallet_balance', $data['amount']);
        Wallet::record($rider, 'referral_credit', 'credit', $data['amount'], 'system', $data['reason'], null, ['admin_id' => $request->user()->id]);

        return back()->with('status', naira($data['amount']).' added to the wallet.');
    }
}
