<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Partner;
use App\Models\Tour;
use App\Models\TourCategory;
use App\Models\TourSlot;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class TourController extends Controller
{
    public function index(Request $request): View
    {
        $tours = Tour::with('partner:id,name', 'category:id,name')
            ->when($request->q, fn ($q, $s) => $q->where('title', 'like', "%$s%"))
            ->when($request->category, fn ($q, $c) => $q->where('tour_category_id', $c))
            ->withCount(['bookings' => fn ($q) => $q->where('status', '!=', 'cancelled')])
            ->orderByDesc('is_published')->orderBy('title')->paginate(25)->withQueryString();

        return view('admin.tours.index', ['tours' => $tours, 'categories' => TourCategory::orderBy('sort_order')->get()]);
    }

    public function create(): View
    {
        return view('admin.tours.form', ['tour' => new Tour(['min_group_size' => 1, 'max_group_size' => 10, 'languages' => ['English']])] + $this->options());
    }

    public function store(Request $request): RedirectResponse
    {
        $tour = Tour::create($this->validated($request));

        return redirect()->route('admin.tours.show', $tour)->with('status', 'Tour created. Add some time slots next.');
    }

    public function show(Tour $tour): View
    {
        $tour->load('partner', 'category');

        return view('admin.tours.show', [
            'tour' => $tour,
            'slots' => $tour->slots()->with('guide:id,first_name,last_name')->where('starts_at', '>=', today())->orderBy('starts_at')->limit(40)->get(),
            'guides' => Driver::where('status', 'approved')->where('is_tour_guide', true)->orderBy('first_name')->get(),
            'reviews' => $tour->reviews()->with('rider:id,first_name,last_name')->latest()->limit(10)->get(),
        ]);
    }

    public function edit(Tour $tour): View
    {
        return view('admin.tours.form', ['tour' => $tour] + $this->options());
    }

    public function update(Request $request, Tour $tour): RedirectResponse
    {
        $tour->update($this->validated($request, $tour));

        return redirect()->route('admin.tours.show', $tour)->with('status', 'Tour saved.');
    }

    public function destroy(Tour $tour): RedirectResponse
    {
        if ($tour->bookings()->exists()) {
            $tour->update(['is_published' => false]);

            return redirect()->route('admin.tours.index')->with('status', 'This tour has bookings, so it was unpublished instead of deleted.');
        }
        $tour->delete();

        return redirect()->route('admin.tours.index')->with('status', 'Tour deleted.');
    }

    /** Add slots at a time of day across a date range. */
    public function storeSlots(Request $request, Tour $tour): RedirectResponse
    {
        $data = $request->validate([
            'from' => 'required|date|after_or_equal:today',
            'to' => 'required|date|after_or_equal:from|before:+6 months',
            'time' => 'required|date_format:H:i',
            'capacity' => 'required|integer|min:1|max:200',
            'days' => 'nullable|array',
            'days.*' => 'integer|between:0,6',
            'guide_driver_id' => 'nullable|exists:drivers,id',
        ]);

        $created = 0;
        $days = $data['days'] ?? range(0, 6);
        [$h, $m] = explode(':', $data['time']);
        for ($d = Carbon::parse($data['from']); $d->lte(Carbon::parse($data['to'])); $d->addDay()) {
            if (! in_array($d->dayOfWeek, $days)) {
                continue;
            }
            $slot = $tour->slots()->firstOrCreate(['starts_at' => $d->copy()->setTime((int) $h, (int) $m)], ['capacity' => $data['capacity'], 'guide_driver_id' => $data['guide_driver_id'] ?? null]);
            $created += $slot->wasRecentlyCreated ? 1 : 0;
        }

        return back()->with('status', "{$created} slots added.");
    }

    public function updateSlot(Request $request, TourSlot $slot): RedirectResponse
    {
        $data = $request->validate([
            'capacity' => 'required|integer|min:'.max(1, $slot->booked).'|max:200',
            'guide_driver_id' => 'nullable|exists:drivers,id',
        ]);
        $slot->update($data);

        return back()->with('status', 'Slot updated.');
    }

    public function destroySlot(TourSlot $slot): RedirectResponse
    {
        if ($slot->bookings()->where('status', '!=', 'cancelled')->exists()) {
            return back()->with('error', 'This slot has bookings. Cancel them first.');
        }
        $slot->delete();

        return back()->with('status', 'Slot removed.');
    }

    private function options(): array
    {
        return [
            'partners' => Partner::whereIn('type', ['tour_operator', 'guide'])->orderBy('name')->get(),
            'categories' => TourCategory::orderBy('sort_order')->get(),
        ];
    }

    private function validated(Request $request, ?Tour $tour = null): array
    {
        $data = $request->validate([
            'title' => 'required|string|max:150',
            'slug' => ['nullable', 'alpha_dash', 'max:160', Rule::unique('tours')->ignore($tour?->id)],
            'partner_id' => 'required|exists:partners,id',
            'tour_category_id' => 'required|exists:tour_categories,id',
            'description' => 'required|string|max:5000',
            'area' => 'required|string|max:80',
            'meeting_point' => 'required|string|max:255',
            'meeting_lat' => 'nullable|numeric|between:-90,90',
            'meeting_lng' => 'nullable|numeric|between:-180,180',
            'duration_minutes' => 'required|integer|min:30|max:1440',
            'price' => 'required|integer|min:0',
            'min_group_size' => 'required|integer|min:1|max:100',
            'max_group_size' => 'required|integer|gte:min_group_size|max:200',
            'languages' => 'nullable|string|max:255',
            'itinerary' => 'nullable|string|max:5000',
            'inclusions' => 'nullable|string|max:3000',
            'exclusions' => 'nullable|string|max:3000',
            'addons' => 'nullable|string|max:3000',
            'cancellation_policy' => 'nullable|string|max:255',
            'image_url' => 'nullable|string|max:255',
            'wheelchair_accessible' => 'boolean',
            'is_featured' => 'boolean',
            'is_published' => 'boolean',
        ]);

        $lines = fn (?string $text) => collect(preg_split('/\r?\n/', (string) $text))->map(fn ($l) => trim($l))->filter()->values()->all();
        $data['slug'] = $data['slug'] ?: Str::slug($data['title']);
        $data['languages'] = collect(explode(',', (string) $data['languages']))->map(fn ($l) => trim($l))->filter()->values()->all();
        $data['itinerary'] = $lines($data['itinerary']);
        $data['inclusions'] = $lines($data['inclusions']);
        $data['exclusions'] = $lines($data['exclusions']);
        // Add-ons are written one per line as "Name | price".
        $data['addons'] = collect($lines($data['addons']))->map(function ($line) {
            [$name, $price] = array_map('trim', explode('|', $line.'|0'));

            return ['code' => Str::slug($name, '_'), 'name' => $name, 'price' => (int) preg_replace('/\D/', '', $price)];
        })->all();
        foreach (['wheelchair_accessible', 'is_featured', 'is_published'] as $flag) {
            $data[$flag] = $request->boolean($flag);
        }

        return $data;
    }
}
