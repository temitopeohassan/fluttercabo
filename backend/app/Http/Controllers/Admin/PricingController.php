<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\RideType;
use App\Models\Zone;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

/** Ride type fares and zone surge multipliers. */
class PricingController extends Controller
{
    public function index(): View
    {
        return view('admin.pricing.index', [
            'rideTypes' => RideType::orderBy('sort_order')->get(),
            'zones' => Zone::orderBy('name')->get(),
        ]);
    }

    public function updateRideType(Request $request, RideType $rideType): RedirectResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:40',
            'description' => 'nullable|string|max:255',
            'seats' => 'required|integer|min:1|max:8',
            'base_fare' => 'required|integer|min:0',
            'per_km' => 'required|integer|min:0',
            'per_minute' => 'required|integer|min:0',
            'minimum_fare' => 'required|integer|min:0',
        ]);
        $rideType->update($data + ['is_active' => $request->boolean('is_active')]);

        return back()->with('status', "{$rideType->name} pricing saved.");
    }

    public function storeZone(Request $request): RedirectResponse
    {
        Zone::create($this->validatedZone($request));

        return back()->with('status', 'Zone added.');
    }

    public function updateZone(Request $request, Zone $zone): RedirectResponse
    {
        $zone->update($this->validatedZone($request));

        return back()->with('status', "{$zone->name} saved.");
    }

    public function destroyZone(Zone $zone): RedirectResponse
    {
        $zone->delete();

        return back()->with('status', 'Zone removed.');
    }

    private function validatedZone(Request $request): array
    {
        return $request->validate([
            'name' => 'required|string|max:80',
            'center_lat' => 'required|numeric|between:-90,90',
            'center_lng' => 'required|numeric|between:-180,180',
            'radius_km' => 'required|numeric|min:0.5|max:50',
            'surge_multiplier' => 'required|numeric|min:1|max:3',
        ]) + [
            'is_service_area' => $request->boolean('is_service_area'),
            'is_active' => $request->boolean('is_active'),
        ];
    }
}
