<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use App\Models\RideType;
use App\Models\ShuttleBooking;
use App\Services\FareCalculator;
use App\Services\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/** Fixed-price airport pickups and drop-offs at Murtala Muhammed (LOS). */
class ShuttleController extends Controller
{
    private const AIRPORT = [6.5774, 3.3212];

    /** Extra charge for an airport job over a normal ride, covering parking and the meet-and-greet. */
    private const AIRPORT_SURCHARGE = 3000;

    public function __construct(private FareCalculator $fares) {}

    public function quote(Request $request): JsonResponse
    {
        $data = $this->validateQuote($request);
        $quotes = RideType::where('is_active', true)->orderBy('sort_order')->get()
            ->filter(fn ($t) => $t->seats >= $data['passengers'])
            ->map(fn ($t) => ['ride_type' => $t->code, 'name' => $t->name, 'seats' => $t->seats, 'price' => $this->price($t, $data)])
            ->values();

        return response()->json(['data' => $quotes]);
    }

    public function index(Request $request): JsonResponse
    {
        return response()->json($request->user()->shuttleBookings()
            ->with('driver:id,first_name,last_name,photo_url,rating', 'driver.activeVehicle:id,driver_id,make,model,colour,plate_number', 'rideType:id,code,name')
            ->orderByDesc('pickup_at')->paginate(20));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validateQuote($request) + $request->validate([
            'ride_type' => 'required|exists:ride_types,code',
            'address' => 'required|string|max:255',
            'flight_number' => 'required|string|max:12',
            'flight_time' => 'required|date|after:now',
            'terminal' => 'nullable|string|max:60',
            'small_bags' => 'nullable|integer|min:0|max:10',
            'name_board' => 'nullable|string|max:60',
            'notes' => 'nullable|string|max:255',
            'payment_method' => 'required|in:card,wallet,bank_transfer',
            'promo_code' => 'nullable|string|max:32',
        ]);

        $type = RideType::where('code', $data['ride_type'])->firstOrFail();
        if ($type->seats < $data['passengers']) {
            throw ValidationException::withMessages(['ride_type' => "{$type->name} seats up to {$type->seats}. Choose a bigger car."]);
        }

        $price = $this->price($type, $data);
        $promo = null;
        if (! empty($data['promo_code'])) {
            $promo = PromoCode::where('code', strtoupper($data['promo_code']))->first();
            $reason = $promo ? $promo->rejectionReason('shuttle', $request->user()) : 'That promo code does not exist.';
            if ($reason) {
                throw ValidationException::withMessages(['promo_code' => $reason]);
            }
            $price -= $promo->discountFor($price);
        }

        $flightTime = Carbon::parse($data['flight_time']);
        $pickup = $data['direction'] === 'airport_pickup' ? $flightTime->copy()->addMinutes(45) : $flightTime->copy()->subHours(4);

        $booking = DB::transaction(function () use ($request, $data, $type, $price, $pickup, $flightTime, $promo) {
            $booking = $request->user()->shuttleBookings()->create([
                'direction' => $data['direction'], 'terminal' => $data['terminal'] ?? null,
                'flight_number' => strtoupper(str_replace(' ', '', $data['flight_number'])), 'flight_time' => $flightTime,
                'pickup_at' => $pickup, 'address' => $data['address'], 'lat' => $data['lat'], 'lng' => $data['lng'],
                'ride_type_id' => $type->id, 'passengers' => $data['passengers'],
                'large_bags' => $data['large_bags'] ?? 0, 'small_bags' => $data['small_bags'] ?? 0,
                'price' => $price, 'driver_payout' => $this->fares->split($price)['driver_earnings'],
                'meeting_point' => $data['direction'] === 'airport_pickup' ? 'Arrivals hall exit, by the Cabo sign at Pillar 3' : null,
                'name_board' => $data['name_board'] ?? ($data['direction'] === 'airport_pickup' ? strtoupper($request->user()->last_name ?? '') : null),
                'notes' => $data['notes'] ?? null,
                'payment_method' => $data['payment_method'], 'payment_status' => 'paid',
            ]);
            Wallet::charge($request->user(), $price, $data['payment_method'], "Airport shuttle {$booking->reference}", $booking);
            $promo?->increment('used_count');

            return $booking;
        });

        return response()->json(['data' => $booking->fresh()], 201);
    }

    public function show(Request $request, ShuttleBooking $shuttle): JsonResponse
    {
        abort_unless($shuttle->rider_id === $request->user()->id, 404);

        return response()->json(['data' => $shuttle->load('driver:id,first_name,last_name,photo_url,rating,phone', 'driver.activeVehicle:id,driver_id,make,model,colour,plate_number', 'rideType:id,code,name')]);
    }

    /** Free cancellation up to 12 hours before pickup; no refund after that. */
    public function cancel(Request $request, ShuttleBooking $shuttle): JsonResponse
    {
        abort_unless($shuttle->rider_id === $request->user()->id, 404);
        if (! in_array($shuttle->status, ['confirmed', 'driver_assigned'], true)) {
            throw ValidationException::withMessages(['shuttle' => 'This booking can no longer be cancelled.']);
        }

        $refund = now()->diffInHours($shuttle->pickup_at, false) >= 12 ? $shuttle->price : 0;
        DB::transaction(function () use ($request, $shuttle, $refund) {
            $shuttle->update(['status' => 'cancelled', 'payment_status' => $refund > 0 ? 'refunded' : 'paid']);
            Wallet::refund($request->user(), $refund, $shuttle->payment_method, "Refund for {$shuttle->reference}", $shuttle);
        });

        return response()->json(['data' => $shuttle->fresh(), 'refund' => $refund]);
    }

    private function validateQuote(Request $request): array
    {
        return $request->validate([
            'direction' => 'required|in:airport_pickup,airport_dropoff',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'passengers' => 'required|integer|min:1|max:7',
            'large_bags' => 'nullable|integer|min:0|max:10',
        ]);
    }

    /** Fixed price: the normal ride fare plus the airport surcharge, rounded up to ₦500. */
    private function price(RideType $type, array $data): int
    {
        $fare = $this->fares->estimate($type, self::AIRPORT[0], self::AIRPORT[1], (float) $data['lat'], (float) $data['lng'])['fare_total'];

        return (int) (ceil(($fare + self::AIRPORT_SURCHARGE) / 500) * 500);
    }
}
