<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use App\Models\RideType;
use App\Models\Trip;
use App\Models\Zone;
use App\Services\FareCalculator;
use App\Services\TripLifecycle;
use App\Services\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class TripController extends Controller
{
    public function __construct(private FareCalculator $fares, private TripLifecycle $lifecycle) {}

    private const DRIVER_FIELDS = 'driver:id,first_name,last_name,photo_url,rating,languages';

    private const VEHICLE_FIELDS = 'vehicle:id,make,model,year,colour,plate_number,seats';

    /** Upfront prices for every ride type on a route. */
    public function estimate(Request $request): JsonResponse
    {
        $data = $this->validateRoute($request);
        $promo = $this->promo($request, $data);

        $estimates = RideType::where('is_active', true)->orderBy('sort_order')->get()
            ->map(fn (RideType $type) => $this->fares->estimate($type, $data['pickup_lat'], $data['pickup_lng'], $data['dropoff_lat'], $data['dropoff_lng'], $data['stops'] ?? [], $promo) + [
                'name' => $type->name, 'seats' => $type->seats, 'description' => $type->description,
            ]);

        return response()->json(['data' => $estimates]);
    }

    public function index(Request $request): JsonResponse
    {
        $trips = $request->user()->trips()->with(self::DRIVER_FIELDS, self::VEHICLE_FIELDS, 'rideType:id,code,name')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->latest()->paginate(20);

        return response()->json($trips);
    }

    public function store(Request $request): JsonResponse
    {
        $rider = $request->user();
        $data = $this->validateRoute($request) + $request->validate([
            'ride_type' => 'required|exists:ride_types,code',
            'pickup_address' => 'required|string|max:255',
            'dropoff_address' => 'required|string|max:255',
            'payment_method' => 'required|in:card,wallet,bank_transfer,cash',
            'scheduled_at' => 'nullable|date|after:+15 minutes|before:+30 days',
        ]);

        if ($rider->trips()->whereIn('status', Trip::ACTIVE_STATUSES)->exists()) {
            throw ValidationException::withMessages(['trip' => 'You already have a ride in progress.']);
        }
        if (! Zone::at($data['pickup_lat'], $data['pickup_lng'])?->is_service_area) {
            throw ValidationException::withMessages(['pickup_lat' => 'Cabo is not available at this pickup point yet.']);
        }

        $type = RideType::where('code', $data['ride_type'])->where('is_active', true)->firstOrFail();
        $promo = $this->promo($request, $data, 'ride');
        $estimate = $this->fares->estimate($type, $data['pickup_lat'], $data['pickup_lng'], $data['dropoff_lat'], $data['dropoff_lng'], $data['stops'] ?? [], $promo);

        if ($data['payment_method'] === 'wallet' && $rider->wallet_balance < $estimate['fare_total']) {
            throw ValidationException::withMessages(['payment_method' => 'Your Cabo wallet balance is too low for this ride.']);
        }

        $trip = $rider->trips()->create([
            'ride_type_id' => $type->id,
            'status' => isset($data['scheduled_at']) ? 'scheduled' : 'requested',
            'scheduled_at' => $data['scheduled_at'] ?? null,
            'pickup_address' => $data['pickup_address'], 'pickup_lat' => $data['pickup_lat'], 'pickup_lng' => $data['pickup_lng'],
            'dropoff_address' => $data['dropoff_address'], 'dropoff_lat' => $data['dropoff_lat'], 'dropoff_lng' => $data['dropoff_lng'],
            'stops' => $data['stops'] ?? null,
            'pin' => str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT),
            'promo_code_id' => $promo?->id,
            'payment_method' => $data['payment_method'],
            'payment_status' => $data['payment_method'] === 'card' ? 'authorised' : 'pending',
            ...collect($estimate)->only(['distance_km', 'duration_minutes', 'surge_multiplier', 'fare_base', 'fare_distance', 'fare_time', 'fare_stops', 'tolls', 'discount', 'fare_total'])->all(),
        ]);

        return response()->json(['data' => $trip->fresh()->load('rideType:id,code,name')], 201);
    }

    public function show(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $trip->load(self::DRIVER_FIELDS, self::VEHICLE_FIELDS, 'rideType:id,code,name');
        $data = $trip->toArray();
        if ($trip->driver && in_array($trip->status, ['accepted', 'arrived', 'in_progress'], true)) {
            $location = $trip->driver()->first(['current_lat', 'current_lng', 'location_updated_at']);
            $data['driver_location'] = [
                'lat' => $location->current_lat,
                'lng' => $location->current_lng,
                'updated_at' => $location->location_updated_at,
            ];
        }
        $data['waiting_fee'] = $this->lifecycle->waitingFee($trip);

        return response()->json(['data' => $data]);
    }

    public function cancel(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $request->validate(['reason' => 'nullable|string|max:255']);
        if (! in_array($trip->status, ['scheduled', 'requested', 'accepted', 'arrived'], true)) {
            throw ValidationException::withMessages(['trip' => 'This ride can no longer be cancelled.']);
        }

        $trip = $this->lifecycle->cancel($trip, 'rider', $request->reason);

        return response()->json(['data' => $trip, 'message' => $trip->cancellation_fee > 0 ? 'Ride cancelled. A ₦'.number_format($trip->cancellation_fee).' cancellation fee applies.' : 'Ride cancelled. No fee was charged.']);
    }

    /** Add a stop before or during the ride; the fare is repriced. */
    public function addStop(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $stop = $request->validate([
            'address' => 'required|string|max:255',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);
        if (! in_array($trip->status, ['requested', 'accepted', 'arrived', 'in_progress'], true)) {
            throw ValidationException::withMessages(['trip' => 'Stops can only be added to an active ride.']);
        }
        $stops = $trip->stops ?? [];
        if (count($stops) >= 3) {
            throw ValidationException::withMessages(['stops' => 'A ride can have up to three stops.']);
        }
        $stops[] = $stop;

        $estimate = $this->fares->estimate($trip->rideType, $trip->pickup_lat, $trip->pickup_lng, $trip->dropoff_lat, $trip->dropoff_lng, $stops, $trip->promoCode);
        $trip->update(['stops' => $stops] + collect($estimate)->only(['distance_km', 'duration_minutes', 'fare_distance', 'fare_time', 'fare_stops', 'tolls', 'discount', 'fare_total'])->all());

        return response()->json(['data' => $trip->fresh()]);
    }

    /** Rate the driver and optionally tip after the ride. */
    public function rate(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        $data = $request->validate([
            'rating' => 'required|integer|between:1,5',
            'feedback' => 'nullable|string|max:255',
            'tip' => 'nullable|integer|min:0|max:50000',
        ]);
        if ($trip->status !== 'completed') {
            throw ValidationException::withMessages(['trip' => 'You can rate a ride once it is complete.']);
        }
        if ($trip->driver_rating !== null) {
            throw ValidationException::withMessages(['rating' => 'You have already rated this ride.']);
        }

        $tip = (int) ($data['tip'] ?? 0);
        if ($tip > 0) {
            $method = $trip->payment_method === 'cash' ? 'card' : $trip->payment_method;
            Wallet::charge($request->user(), $tip, $method, "Tip for {$trip->reference}", $trip);
            Wallet::creditDriver($trip->driver, $tip, 'tip', "Tip on {$trip->reference}", $trip);
        }

        $trip->update([
            'driver_rating' => $data['rating'],
            'driver_feedback' => $data['feedback'] ?? null,
            'tip' => $tip,
            'driver_earnings' => $trip->driver_earnings + $tip,
        ]);
        $trip->driver->update(['rating' => round((float) Trip::where('driver_id', $trip->driver_id)->whereNotNull('driver_rating')->avg('driver_rating'), 2)]);

        return response()->json(['data' => $trip->fresh()]);
    }

    /** A link family can open to follow the ride live. */
    public function share(Request $request, Trip $trip): JsonResponse
    {
        $this->authorizeTrip($request, $trip);
        if (! $trip->share_token) {
            $trip->update(['share_token' => Str::random(24)]);
        }

        return response()->json(['data' => ['url' => url("/trip/{$trip->share_token}"), 'token' => $trip->share_token]]);
    }

    private function authorizeTrip(Request $request, Trip $trip): void
    {
        abort_unless($trip->rider_id === $request->user()->id, 404);
    }

    private function validateRoute(Request $request): array
    {
        return $request->validate([
            'pickup_lat' => 'required|numeric|between:-90,90',
            'pickup_lng' => 'required|numeric|between:-180,180',
            'dropoff_lat' => 'required|numeric|between:-90,90',
            'dropoff_lng' => 'required|numeric|between:-180,180',
            'stops' => 'nullable|array|max:3',
            'stops.*.address' => 'required_with:stops|string|max:255',
            'stops.*.lat' => 'required_with:stops|numeric|between:-90,90',
            'stops.*.lng' => 'required_with:stops|numeric|between:-180,180',
            'promo_code' => 'nullable|string|max:32',
        ]);
    }

    private function promo(Request $request, array $data, string $service = 'ride'): ?PromoCode
    {
        if (empty($data['promo_code'])) {
            return null;
        }
        $promo = PromoCode::where('code', strtoupper($data['promo_code']))->first();
        $reason = $promo ? $promo->rejectionReason($service, $request->user()) : 'That promo code does not exist.';
        if ($reason) {
            throw ValidationException::withMessages(['promo_code' => $reason]);
        }

        return $promo;
    }
}
