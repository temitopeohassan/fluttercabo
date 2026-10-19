<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attraction;
use App\Models\RideType;
use App\Models\Setting;
use App\Models\Tour;
use App\Models\TourCategory;
use App\Models\WaitlistSignup;
use App\Models\Zone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Endpoints the apps and website can call without signing in. */
class PublicController extends Controller
{
    public function config(): JsonResponse
    {
        $settings = fn (string $key, $default = null) => Setting::read($key, $default);

        return response()->json(['data' => [
            'currency' => 'NGN',
            'exchange_rates' => [
                'GBP' => (float) $settings('gbp_rate', 2000),
                'USD' => (float) $settings('usd_rate', 1550),
                'EUR' => (float) $settings('eur_rate', 1700),
            ],
            'waiting' => [
                'free_minutes' => (int) $settings('free_waiting_minutes', 5),
                'fee_per_minute' => (int) $settings('waiting_fee_per_minute', 50),
                'airport_free_minutes' => (int) $settings('airport_free_waiting_minutes', 60),
            ],
            'cancellation' => [
                'free_minutes' => (int) $settings('free_cancellation_minutes', 2),
                'rider_fee' => (int) $settings('rider_cancellation_fee', 500),
                'tour_free_hours' => (int) $settings('tour_free_cancellation_hours', 24),
            ],
            'drivers' => [
                'commission_rate' => (float) $settings('commission_rate', 20),
                'cash_debt_limit' => (int) $settings('cash_debt_limit', 20000),
                'instant_cashout_fee_percent' => (float) $settings('instant_cashout_fee_percent', 1.5),
                'minimum_cashout' => (int) $settings('minimum_cashout', 5000),
            ],
            'support' => [
                'phone' => $settings('support_phone'),
                'email' => $settings('support_email'),
                'emergency_number' => $settings('emergency_number', '112'),
            ],
            'service_areas' => Zone::where('is_active', true)->where('is_service_area', true)
                ->get(['name', 'center_lat', 'center_lng', 'radius_km']),
            'ride_types' => RideType::where('is_active', true)->orderBy('sort_order')->get(),
        ]]);
    }

    public function rideTypes(): JsonResponse
    {
        return response()->json(['data' => RideType::where('is_active', true)->orderBy('sort_order')->get()]);
    }

    public function tourCategories(): JsonResponse
    {
        return response()->json(['data' => TourCategory::orderBy('sort_order')->withCount(['tours' => fn ($q) => $q->where('is_published', true)])->get()]);
    }

    public function tours(Request $request): JsonResponse
    {
        $request->validate([
            'category' => 'nullable|string',
            'q' => 'nullable|string|max:100',
            'max_price' => 'nullable|integer|min:0',
            'date' => 'nullable|date',
            'sort' => 'nullable|in:popular,rating,price_low,price_high',
        ]);

        $tours = Tour::query()->where('is_published', true)->with('category:id,name,slug', 'partner:id,name')
            ->when($request->category, fn ($q, $c) => $q->whereHas('category', fn ($q) => $q->where('slug', $c)))
            ->when($request->q, fn ($q, $s) => $q->where(fn ($q) => $q->where('title', 'like', "%$s%")->orWhere('area', 'like', "%$s%")))
            ->when($request->max_price, fn ($q, $p) => $q->where('price', '<=', $p))
            ->when($request->boolean('wheelchair'), fn ($q) => $q->where('wheelchair_accessible', true))
            ->when($request->boolean('featured'), fn ($q) => $q->where('is_featured', true))
            ->when($request->date, fn ($q, $d) => $q->whereHas('slots', fn ($q) => $q->whereDate('starts_at', $d)->whereColumn('booked', '<', 'capacity')));

        match ($request->sort) {
            'rating' => $tours->orderByDesc('rating'),
            'price_low' => $tours->orderBy('price'),
            'price_high' => $tours->orderByDesc('price'),
            default => $tours->orderByDesc('is_featured')->orderByDesc('reviews_count'),
        };

        return response()->json($tours->paginate(20));
    }

    public function tour(Tour $tour): JsonResponse
    {
        abort_unless($tour->is_published, 404);

        $tour->load('category:id,name,slug', 'partner:id,name');
        $tour->setRelation('reviews', $tour->reviews()->where('is_visible', true)->with('rider:id,first_name,last_name,nationality')->latest()->limit(10)->get());

        return response()->json(['data' => $tour]);
    }

    public function tourSlots(Request $request, Tour $tour): JsonResponse
    {
        abort_unless($tour->is_published, 404);
        $from = $request->date('from') ?? now();

        $slots = $tour->slots()->where('starts_at', '>', $from)->where('starts_at', '<', $from->copy()->addDays(30))
            ->orderBy('starts_at')->get(['id', 'tour_id', 'starts_at', 'capacity', 'booked']);

        return response()->json(['data' => $slots]);
    }

    public function attractions(Request $request): JsonResponse
    {
        $attractions = Attraction::where('is_published', true)
            ->when($request->category, fn ($q, $c) => $q->where('category', $c))
            ->when($request->area, fn ($q, $a) => $q->where('area', $a))
            ->when($request->q, fn ($q, $s) => $q->where('name', 'like', "%$s%"))
            ->orderByDesc('reviews_count')->get();

        return response()->json(['data' => $attractions]);
    }

    public function attraction(Attraction $attraction): JsonResponse
    {
        abort_unless($attraction->is_published, 404);

        return response()->json(['data' => $attraction]);
    }

    /** The website's "Join the waitlist" form posts here. */
    public function waitlist(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email:rfc|max:190',
            'source' => 'nullable|string|max:32',
        ]);

        $signup = WaitlistSignup::firstOrCreate(
            ['email' => strtolower($data['email'])],
            ['name' => $data['name'], 'source' => $data['source'] ?? 'website', 'ip_address' => $request->ip()],
        );

        return response()->json([
            'message' => $signup->wasRecentlyCreated ? "You're on the list. We'll email you when Cabo launches." : "You're already on the list.",
        ], $signup->wasRecentlyCreated ? 201 : 200);
    }
}
