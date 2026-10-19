<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\Trip;
use App\Services\TripLifecycle;
use App\Support\Geo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/** Ride requests and the trip flow on the driver side. The rider's PIN is never sent to the driver. */
class TripController extends Controller
{
    /** How far away a request can be offered to a driver. */
    private const OFFER_RADIUS_KM = 8;

    private const RIDER_FIELDS = 'rider:id,first_name,photo_url,rating,accessibility';

    public function __construct(private TripLifecycle $lifecycle) {}

    /** Open requests near the driver that their vehicle qualifies for. */
    public function available(Request $request): JsonResponse
    {
        $driver = $request->user();
        if (! $driver->is_online) {
            return response()->json(['data' => [], 'message' => 'Go online to receive requests.']);
        }
        $vehicle = $driver->activeVehicle;
        $types = $vehicle?->ride_types ?? [];

        $trips = Trip::where('status', 'requested')->whereNull('driver_id')
            ->whereHas('rideType', fn ($q) => $q->whereIn('code', $types))
            ->with(self::RIDER_FIELDS, 'rideType:id,code,name')->latest()->limit(50)->get()
            ->reject(fn (Trip $t) => in_array($driver->id, $t->declined_driver_ids ?? [], true))
            ->map(function (Trip $t) use ($driver) {
                $t->pickup_distance_km = $driver->current_lat !== null
                    ? round(Geo::distanceKm($driver->current_lat, $driver->current_lng, $t->pickup_lat, $t->pickup_lng), 2)
                    : null;

                return $t;
            })
            ->filter(fn (Trip $t) => $t->pickup_distance_km === null || $t->pickup_distance_km <= self::OFFER_RADIUS_KM)
            ->sortBy('pickup_distance_km')->values()
            ->each->makeHidden('pin');

        return response()->json(['data' => $trips]);
    }

    public function current(Request $request): JsonResponse
    {
        $trip = $request->user()->trips()->whereIn('status', ['accepted', 'arrived', 'in_progress'])
            ->with(self::RIDER_FIELDS, 'rideType:id,code,name')->latest()->first();

        return response()->json(['data' => $trip?->makeHidden('pin')]);
    }

    public function index(Request $request): JsonResponse
    {
        $trips = $request->user()->trips()->with('rideType:id,code,name', 'rider:id,first_name')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->latest()->paginate(20);
        $trips->getCollection()->each->makeHidden('pin');

        return response()->json($trips);
    }

    public function show(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);

        return response()->json(['data' => $trip->load(self::RIDER_FIELDS, 'rideType:id,code,name')->makeHidden('pin')]);
    }

    public function accept(Request $request, Trip $trip): JsonResponse
    {
        $driver = $request->user();
        if (! $driver->is_online) {
            throw ValidationException::withMessages(['trip' => 'Go online to accept requests.']);
        }
        if ($driver->trips()->whereIn('status', ['accepted', 'arrived', 'in_progress'])->exists()) {
            throw ValidationException::withMessages(['trip' => 'Finish your current trip first.']);
        }
        $vehicle = $driver->activeVehicle;
        if (! $vehicle || ! in_array($trip->rideType->code, $vehicle->ride_types ?? [], true)) {
            throw ValidationException::withMessages(['trip' => 'Your vehicle does not qualify for this ride type.']);
        }

        // Only one driver can win the request.
        $won = Trip::whereKey($trip->id)->where('status', 'requested')->whereNull('driver_id')->update([
            'driver_id' => $driver->id, 'vehicle_id' => $vehicle->id, 'status' => 'accepted', 'accepted_at' => now(),
        ]);
        if (! $won) {
            return response()->json(['message' => 'This request is no longer available.'], 409);
        }

        $trip = $trip->fresh()->load(self::RIDER_FIELDS, 'rideType:id,code,name');
        $trip->rider->appNotifications()->create([
            'type' => 'trip', 'title' => "{$driver->first_name} is on the way",
            'body' => "{$vehicle->description} · {$vehicle->plate_number}", 'data' => ['trip_id' => $trip->id],
        ]);

        return response()->json(['data' => $trip->makeHidden('pin')]);
    }

    public function decline(Request $request, Trip $trip): JsonResponse
    {
        $driver = $request->user();
        DB::transaction(function () use ($trip, $driver) {
            $trip = Trip::lockForUpdate()->find($trip->id);
            $declined = $trip->declined_driver_ids ?? [];
            $declined[] = $driver->id;
            $trip->update(['declined_driver_ids' => array_values(array_unique($declined))]);
        });

        $offers = Trip::where('created_at', '>', now()->subDays(30))->whereJsonContains('declined_driver_ids', $driver->id)->count();
        $accepted = $driver->trips()->where('created_at', '>', now()->subDays(30))->count();
        if ($offers + $accepted > 0) {
            $driver->update(['acceptance_rate' => round($accepted / ($offers + $accepted) * 100, 1)]);
        }

        return response()->json(['message' => 'Request declined.']);
    }

    public function arrive(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $this->expectStatus($trip, 'accepted');
        $trip->update(['status' => 'arrived', 'arrived_at' => now()]);
        $trip->rider->appNotifications()->create(['type' => 'trip', 'title' => 'Your driver has arrived', 'body' => "Share your PIN {$trip->pin} only once you are in the car.", 'data' => ['trip_id' => $trip->id]]);

        return response()->json(['data' => $trip->makeHidden('pin')]);
    }

    /** The rider tells the driver their 4-digit PIN to start the ride. */
    public function start(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $this->expectStatus($trip, 'arrived');
        $request->validate(['pin' => 'required|digits:4']);
        if (! hash_equals($trip->pin, $request->pin)) {
            throw ValidationException::withMessages(['pin' => 'That PIN does not match. Ask the rider to check their app.']);
        }
        $trip->update(['status' => 'in_progress', 'started_at' => now()]);

        return response()->json(['data' => $trip->makeHidden('pin')]);
    }

    public function complete(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $this->expectStatus($trip, 'in_progress');
        $trip = $this->lifecycle->complete($trip->load('rider', 'driver'));

        return response()->json(['data' => $trip->makeHidden('pin'), 'collect_cash' => $trip->payment_method === 'cash' ? $trip->fare_total : 0]);
    }

    public function collectCash(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        if ($trip->status !== 'completed' || $trip->payment_method !== 'cash' || $trip->payment_status === 'paid') {
            throw ValidationException::withMessages(['trip' => 'There is no cash to collect on this trip.']);
        }
        $trip = $this->lifecycle->collectCash($trip->load('rider', 'driver'));

        return response()->json(['data' => $trip->makeHidden('pin'), 'cash_commission_owed' => $trip->driver->fresh()->cash_commission_owed]);
    }

    public function cancel(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $data = $request->validate(['reason' => 'required|string|max:255']);
        if (! in_array($trip->status, ['accepted', 'arrived'], true)) {
            throw ValidationException::withMessages(['trip' => 'This trip can no longer be cancelled.']);
        }
        if ($data['reason'] === 'no_show') {
            $this->expectStatus($trip, 'arrived');
            $free = (int) Setting::read('free_waiting_minutes', 5);
            if ($trip->arrived_at->diffInMinutes(now()) < $free) {
                throw ValidationException::withMessages(['reason' => "Wait at least {$free} minutes before marking a no-show."]);
            }
        }

        $trip = $this->lifecycle->cancel($trip->load('rider', 'driver'), 'driver', $data['reason']);

        return response()->json(['data' => $trip->makeHidden('pin')]);
    }

    /** Driver rates the rider after the trip. */
    public function rate(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $data = $request->validate(['rating' => 'required|integer|between:1,5', 'feedback' => 'nullable|string|max:255']);
        $this->expectStatus($trip, 'completed');
        if ($trip->rider_rating !== null) {
            throw ValidationException::withMessages(['rating' => 'You have already rated this rider.']);
        }
        $trip->update(['rider_rating' => $data['rating'], 'rider_feedback' => $data['feedback'] ?? null]);
        $trip->rider->update(['rating' => round((float) Trip::where('rider_id', $trip->rider_id)->whereNotNull('rider_rating')->avg('rider_rating'), 2)]);

        return response()->json(['data' => $trip->makeHidden('pin')]);
    }

    private function authorizeTrip(Request $request, Trip $trip): void
    {
        abort_unless($trip->driver_id === $request->user()->id, 404);
    }

    private function expectStatus(Trip $trip, string $status): void
    {
        if ($trip->status !== $status) {
            throw ValidationException::withMessages(['trip' => "This trip is {$trip->status}, not {$status}."]);
        }
    }
}
