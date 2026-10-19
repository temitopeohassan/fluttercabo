<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Services\TripLifecycle;
use App\Services\Wallet;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TripController extends Controller
{
    public function index(Request $request): View
    {
        $trips = Trip::with('rider:id,first_name,last_name', 'driver:id,first_name,last_name', 'rideType:id,name')
            ->when($request->q, fn ($q, $s) => $q->where(fn ($q) => $q->where('reference', 'like', "%$s%")->orWhere('pickup_address', 'like', "%$s%")->orWhere('dropoff_address', 'like', "%$s%")))
            ->when($request->status === 'active', fn ($q) => $q->whereIn('status', Trip::ACTIVE_STATUSES), fn ($q) => $q->when($request->status, fn ($q, $s) => $q->where('status', $s)))
            ->when($request->payment, fn ($q, $p) => $q->where('payment_method', $p))
            ->when($request->from, fn ($q, $d) => $q->whereDate('created_at', '>=', $d))
            ->when($request->to, fn ($q, $d) => $q->whereDate('created_at', '<=', $d))
            ->latest()->paginate(30)->withQueryString();

        return view('admin.trips.index', compact('trips'));
    }

    public function show(Trip $trip): View
    {
        $trip->load('rider', 'driver', 'vehicle', 'rideType', 'promoCode', 'transactions');

        return view('admin.trips.show', compact('trip'));
    }

    public function cancel(Request $request, Trip $trip, TripLifecycle $lifecycle): RedirectResponse
    {
        $data = $request->validate(['reason' => 'required|string|max:255']);
        abort_unless(in_array($trip->status, ['scheduled', 'requested', 'accepted', 'arrived', 'in_progress'], true), 422, 'This trip has already ended.');
        $lifecycle->cancel($trip, 'admin', $data['reason']);

        return back()->with('status', "Trip {$trip->reference} cancelled.");
    }

    /** Refund some or all of a fare, for example after a fare dispute. */
    public function refund(Request $request, Trip $trip): RedirectResponse
    {
        $paid = $trip->fare_total + $trip->tip + $trip->cancellation_fee;
        $refunded = (int) $trip->transactions()->where('type', 'refund')->sum('amount');
        $data = $request->validate([
            'amount' => 'required|integer|min:1|max:'.max(1, $paid - $refunded),
            'to_wallet' => 'boolean',
            'reason' => 'required|string|max:255',
        ]);
        $method = $request->boolean('to_wallet') || $trip->payment_method === 'cash' ? 'wallet' : $trip->payment_method;
        Wallet::refund($trip->rider, $data['amount'], $method, "Refund {$trip->reference}: {$data['reason']}", $trip);
        if ($paid <= $data['amount'] + $refunded) {
            $trip->update(['payment_status' => 'refunded']);
        }

        return back()->with('status', naira($data['amount']).' refunded to '.($method === 'wallet' ? 'the Cabo wallet' : humanize($method)).'.');
    }
}
