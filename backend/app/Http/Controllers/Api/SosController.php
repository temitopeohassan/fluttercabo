<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SosAlert;
use App\Models\Trip;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/** The SOS button in both apps. Open alerts appear at the top of the admin panel. */
class SosController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'trip_id' => 'nullable|integer',
            'lat' => 'nullable|numeric|between:-90,90',
            'lng' => 'nullable|numeric|between:-180,180',
            'address' => 'nullable|string|max:255',
        ]);

        $trip = isset($data['trip_id']) ? Trip::find($data['trip_id']) : null;
        $owns = $trip && ($user->getMorphClass() === 'rider' ? $trip->rider_id === $user->id : $trip->driver_id === $user->id);

        $alert = SosAlert::create([
            'raised_by_type' => $user->getMorphClass(), 'raised_by_id' => $user->id,
            'trip_id' => $owns ? $trip->id : null,
            'lat' => $data['lat'] ?? null, 'lng' => $data['lng'] ?? null, 'address' => $data['address'] ?? null,
        ]);
        Log::warning("SOS raised by {$user->getMorphClass()} {$user->id}", ['alert' => $alert->id, 'trip' => $alert->trip_id]);

        $contacts = $user->getMorphClass() === 'rider' ? $user->emergencyContacts()->get(['name', 'phone']) : [];

        return response()->json([
            'data' => $alert,
            'message' => 'Cabo safety team alerted. If you are in danger, call 112 now.',
            'emergency_number' => '112',
            'contacts_notified' => $contacts,
        ], 201);
    }

    public function update(Request $request, SosAlert $alert): JsonResponse
    {
        $user = $request->user();
        abort_unless($alert->raised_by_type === $user->getMorphClass() && $alert->raised_by_id === $user->id, 404);
        $data = $request->validate(['lat' => 'required|numeric', 'lng' => 'required|numeric', 'address' => 'nullable|string|max:255']);
        $alert->update($data);

        return response()->json(['data' => $alert]);
    }
}
