<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\ShuttleBooking;
use App\Services\Wallet;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ShuttleController extends Controller
{
    public function index(Request $request): View
    {
        $shuttles = ShuttleBooking::with('rider:id,first_name,last_name', 'driver:id,first_name,last_name', 'rideType:id,name')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->when === 'past', fn ($q) => $q->where('pickup_at', '<', now())->orderByDesc('pickup_at'), fn ($q) => $q->where('pickup_at', '>=', now()->subHours(6))->orderBy('pickup_at'))
            ->paginate(30)->withQueryString();

        return view('admin.shuttles.index', compact('shuttles'));
    }

    public function show(ShuttleBooking $shuttle): View
    {
        $shuttle->load('rider', 'driver.activeVehicle', 'rideType');
        $code = $shuttle->rideType->code;
        $drivers = Driver::where('status', 'approved')->with('activeVehicle')->orderBy('first_name')->get()
            ->filter(fn ($d) => in_array($code, $d->activeVehicle?->ride_types ?? [], true));

        return view('admin.shuttles.show', compact('shuttle', 'drivers'));
    }

    public function update(Request $request, ShuttleBooking $shuttle): RedirectResponse
    {
        $data = $request->validate([
            'driver_id' => 'nullable|exists:drivers,id',
            'flight_status' => 'required|in:scheduled,on_time,delayed,landed,cancelled',
            'flight_time' => 'required|date',
            'pickup_at' => 'required|date',
            'meeting_point' => 'nullable|string|max:255',
        ]);

        $assigning = $data['driver_id'] && (int) $data['driver_id'] !== $shuttle->driver_id;
        $shuttle->fill($data);
        if ($assigning) {
            $shuttle->status = 'driver_assigned';
            $shuttle->driver_assigned_at = now();
        } elseif (! $data['driver_id'] && $shuttle->status === 'driver_assigned') {
            $shuttle->status = 'confirmed';
            $shuttle->driver_assigned_at = null;
        }
        $shuttle->save();

        if ($assigning) {
            $shuttle->driver->appNotifications()->create([
                'type' => 'shuttle', 'title' => 'New airport job',
                'body' => humanize($shuttle->direction).' · '.$shuttle->flight_number.' · '.$shuttle->pickup_at->format('D j M H:i'),
                'data' => ['shuttle_booking_id' => $shuttle->id],
            ]);
        }

        return back()->with('status', 'Shuttle booking updated.');
    }

    public function cancel(Request $request, ShuttleBooking $shuttle): RedirectResponse
    {
        abort_if(in_array($shuttle->status, ['completed', 'cancelled'], true), 422);
        $refund = $request->boolean('refund');
        $shuttle->update(['status' => 'cancelled', 'payment_status' => $refund ? 'refunded' : $shuttle->payment_status]);
        if ($refund) {
            Wallet::refund($shuttle->rider, $shuttle->price, $shuttle->payment_method, "Refund for {$shuttle->reference}", $shuttle);
        }

        return back()->with('status', 'Shuttle booking cancelled'.($refund ? ' and refunded.' : '.'));
    }
}
