<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\ShuttleBooking;
use App\Models\TourBooking;
use App\Models\TourSlot;
use App\Services\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/** Airport shuttles and guided tours assigned to the driver. */
class JobController extends Controller
{
    public function shuttles(Request $request): JsonResponse
    {
        $driver = $request->user();
        $assigned = $driver->shuttleBookings()->with('rider:id,first_name,last_name,phone', 'rideType:id,code,name')
            ->whereIn('status', ['driver_assigned', 'in_progress'])->orderBy('pickup_at')->get();

        // Unassigned bookings the driver's vehicle can take, for drivers who opt in to shuttles.
        $open = collect();
        if (in_array('shuttles', $driver->preferences['jobs'] ?? [], true) && $driver->status === 'approved') {
            $types = $driver->activeVehicle?->ride_types ?? [];
            $open = ShuttleBooking::where('status', 'confirmed')->whereNull('driver_id')->where('pickup_at', '>', now())
                ->whereHas('rideType', fn ($q) => $q->whereIn('code', $types))
                ->with('rideType:id,code,name')->orderBy('pickup_at')->limit(20)
                ->get(['id', 'reference', 'direction', 'terminal', 'flight_number', 'flight_time', 'pickup_at', 'address', 'ride_type_id', 'passengers', 'large_bags', 'driver_payout']);
        }

        return response()->json(['data' => ['assigned' => $assigned, 'open' => $open]]);
    }

    public function claimShuttle(Request $request, ShuttleBooking $shuttle): JsonResponse
    {
        $driver = $request->user();
        if ($driver->status !== 'approved') {
            throw ValidationException::withMessages(['shuttle' => 'Only approved drivers can take airport jobs.']);
        }
        $won = ShuttleBooking::whereKey($shuttle->id)->where('status', 'confirmed')->whereNull('driver_id')
            ->update(['driver_id' => $driver->id, 'status' => 'driver_assigned', 'driver_assigned_at' => now()]);
        if (! $won) {
            return response()->json(['message' => 'This job has already been taken.'], 409);
        }

        return response()->json(['data' => $shuttle->fresh()]);
    }

    public function updateShuttle(Request $request, ShuttleBooking $shuttle): JsonResponse
    {
        abort_unless($shuttle->driver_id === $request->user()->id, 404);
        $data = $request->validate(['status' => 'required|in:in_progress,completed']);
        $allowed = ['in_progress' => 'driver_assigned', 'completed' => 'in_progress'];
        if ($shuttle->status !== $allowed[$data['status']]) {
            throw ValidationException::withMessages(['status' => "This job is {$shuttle->status}."]);
        }
        $shuttle->update(['status' => $data['status']]);
        if ($data['status'] === 'completed') {
            Wallet::creditDriver($request->user(), $shuttle->driver_payout, 'driver_earning', "Airport shuttle {$shuttle->reference}", $shuttle);
        }

        return response()->json(['data' => $shuttle]);
    }

    /** Tour slots where the driver is the guide, with the guest list. */
    public function tours(Request $request): JsonResponse
    {
        $slots = $request->user()->tourSlots()->where('starts_at', '>', now()->subHours(12))
            ->with(['tour:id,title,meeting_point,duration_minutes', 'bookings' => fn ($q) => $q->where('status', '!=', 'cancelled')->with('rider:id,first_name,last_name,phone')])
            ->orderBy('starts_at')->get();

        return response()->json(['data' => $slots]);
    }

    /** Guide scans the rider's QR ticket at the meeting point. */
    public function checkIn(Request $request): JsonResponse
    {
        $data = $request->validate(['qr_token' => 'required|string']);
        $booking = TourBooking::where('qr_token', $data['qr_token'])->with('slot', 'rider:id,first_name,last_name')->first();
        if (! $booking || $booking->slot->guide_driver_id !== $request->user()->id) {
            return response()->json(['message' => 'This ticket is not for one of your tours.'], 404);
        }
        if ($booking->status !== 'confirmed') {
            throw ValidationException::withMessages(['qr_token' => "This ticket is {$booking->status}."]);
        }
        if (! $booking->slot->starts_at->isToday()) {
            throw ValidationException::withMessages(['qr_token' => 'This ticket is for '.$booking->slot->starts_at->format('D j M').'.']);
        }
        $booking->update(['status' => 'checked_in', 'checked_in_at' => now()]);

        return response()->json(['data' => $booking]);
    }

    public function completeTour(Request $request, TourSlot $slot): JsonResponse
    {
        abort_unless($slot->guide_driver_id === $request->user()->id, 404);
        $slot->bookings()->where('status', 'checked_in')->update(['status' => 'completed']);

        return response()->json(['data' => $slot->load('bookings')]);
    }
}
