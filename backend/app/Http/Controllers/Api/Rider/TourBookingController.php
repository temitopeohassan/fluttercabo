<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use App\Models\Review;
use App\Models\Setting;
use App\Models\Tour;
use App\Models\TourBooking;
use App\Models\TourSlot;
use App\Services\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class TourBookingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $bookings = $request->user()->tourBookings()
            ->with('tour:id,title,slug,area,meeting_point,duration_minutes,image_url', 'slot:id,starts_at', 'review')
            ->when($request->status === 'upcoming', fn ($q) => $q->whereIn('status', ['confirmed', 'checked_in']))
            ->when($request->status === 'past', fn ($q) => $q->whereIn('status', ['completed', 'cancelled']))
            ->latest()->paginate(20);

        return response()->json($bookings);
    }

    public function store(Request $request): JsonResponse
    {
        $rider = $request->user();
        $data = $request->validate([
            'tour_id' => 'required|exists:tours,id',
            'tour_slot_id' => 'required|exists:tour_slots,id',
            'guests' => 'required|integer|min:1|max:50',
            'addons' => 'nullable|array',
            'addons.*' => 'string',
            'include_ride' => 'boolean',
            'promo_code' => 'nullable|string|max:32',
            'payment_method' => 'required|in:card,wallet,bank_transfer',
            'company_name' => 'nullable|string|max:120',
        ]);

        $tour = Tour::where('is_published', true)->findOrFail($data['tour_id']);
        $addons = collect($data['addons'] ?? [])->unique()->map(function ($code) use ($tour) {
            $addon = $tour->addon($code);
            if (! $addon) {
                throw ValidationException::withMessages(['addons' => "Unknown add-on: {$code}."]);
            }

            return $addon;
        })->values();
        if ($data['guests'] < $tour->min_group_size) {
            throw ValidationException::withMessages(['guests' => "This tour needs at least {$tour->min_group_size} guests."]);
        }

        $promo = null;
        if (! empty($data['promo_code'])) {
            $promo = PromoCode::where('code', strtoupper($data['promo_code']))->first();
            $reason = $promo ? $promo->rejectionReason('tour', $rider) : 'That promo code does not exist.';
            if ($reason) {
                throw ValidationException::withMessages(['promo_code' => $reason]);
            }
        }

        $booking = DB::transaction(function () use ($rider, $tour, $data, $addons, $promo) {
            // Lock the slot so two people cannot take the last places at once.
            $slot = TourSlot::whereKey($data['tour_slot_id'])->where('tour_id', $tour->id)->lockForUpdate()->first();
            if (! $slot || $slot->starts_at->isPast()) {
                throw ValidationException::withMessages(['tour_slot_id' => 'That time is no longer available.']);
            }
            if ($slot->booked + $data['guests'] > $slot->capacity) {
                $left = $slot->capacity - $slot->booked;
                throw ValidationException::withMessages(['guests' => $left > 0 ? "Only {$left} places are left for this time." : 'This time is fully booked.']);
            }

            $subtotal = $tour->price * $data['guests'];
            $addonsTotal = (int) $addons->sum('price');
            $ride = ! empty($data['include_ride']) ? (int) Setting::read('tour_ride_addon_price', 4000) : 0;
            $gross = $subtotal + $addonsTotal + $ride;
            $discount = $promo ? $promo->discountFor($gross) : 0;

            $booking = $rider->tourBookings()->create([
                'tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => $data['guests'],
                'subtotal' => $subtotal, 'addons' => $addons->all(), 'addons_total' => $addonsTotal,
                'ride_addon_price' => $ride, 'promo_code_id' => $promo?->id, 'discount' => $discount,
                'total' => $gross - $discount, 'payment_method' => $data['payment_method'], 'payment_status' => 'paid',
                'qr_token' => Str::random(32), 'company_name' => $data['company_name'] ?? null,
            ]);
            $slot->increment('booked', $data['guests']);
            $promo?->increment('used_count');
            Wallet::charge($rider, $booking->total, $data['payment_method'], "Tour {$booking->reference}: {$tour->title}", $booking);

            return $booking;
        });

        return response()->json(['data' => $booking->load('tour:id,title,meeting_point', 'slot:id,starts_at')], 201);
    }

    public function show(Request $request, TourBooking $booking): JsonResponse
    {
        abort_unless($booking->rider_id === $request->user()->id, 404);

        return response()->json(['data' => $booking->load('tour', 'slot', 'review')]);
    }

    /** Full refund up to 24 hours before the start, 50% after, nothing once it has begun. */
    public function cancel(Request $request, TourBooking $booking): JsonResponse
    {
        abort_unless($booking->rider_id === $request->user()->id, 404);
        if ($booking->status !== 'confirmed') {
            throw ValidationException::withMessages(['booking' => 'This booking can no longer be cancelled.']);
        }

        $hours = now()->diffInHours($booking->slot->starts_at, false);
        $free = (int) Setting::read('tour_free_cancellation_hours', 24);
        $refund = match (true) {
            $hours >= $free => $booking->total,
            $hours > 0 => (int) round($booking->total / 2),
            default => 0,
        };

        DB::transaction(function () use ($booking, $refund, $request) {
            $booking->update([
                'status' => 'cancelled', 'cancelled_at' => now(), 'refund_amount' => $refund,
                'payment_status' => $refund === $booking->total ? 'refunded' : ($refund > 0 ? 'partially_refunded' : 'paid'),
            ]);
            $booking->slot()->decrement('booked', $booking->guests);
            Wallet::refund($request->user(), $refund, $booking->payment_method, "Refund for {$booking->reference}", $booking);
        });

        return response()->json(['data' => $booking->fresh(), 'refund' => $refund]);
    }

    /** Only riders who checked in can review, once per booking. */
    public function review(Request $request, TourBooking $booking): JsonResponse
    {
        abort_unless($booking->rider_id === $request->user()->id, 404);
        $data = $request->validate([
            'rating' => 'required|integer|between:1,5',
            'comment' => 'nullable|string|max:2000',
            'highlights' => 'nullable|array',
            'highlights.*' => 'string|max:40',
        ]);
        if (! $booking->checked_in_at) {
            throw ValidationException::withMessages(['booking' => 'You can review a tour after you have checked in.']);
        }
        if ($booking->review()->exists()) {
            throw ValidationException::withMessages(['booking' => 'You have already reviewed this tour.']);
        }

        $review = Review::create($data + ['rider_id' => $booking->rider_id, 'tour_id' => $booking->tour_id, 'tour_booking_id' => $booking->id]);
        $booking->tour->refreshRating();

        return response()->json(['data' => $review], 201);
    }
}
