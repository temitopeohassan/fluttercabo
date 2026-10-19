<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\EmergencyContact;
use App\Models\SavedPlace;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $rider = $request->user()->load('emergencyContacts', 'savedPlaces');

        return response()->json(['data' => $rider]);
    }

    public function update(Request $request): JsonResponse
    {
        $rider = $request->user();
        $data = $request->validate([
            'first_name' => 'sometimes|required|string|max:80',
            'last_name' => 'sometimes|required|string|max:80',
            'email' => ['sometimes', 'nullable', 'email', 'max:190', Rule::unique('riders')->ignore($rider->id)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:32', Rule::unique('riders')->ignore($rider->id)],
            'photo_url' => 'sometimes|nullable|url|max:255',
            'nationality' => 'sometimes|nullable|string|max:60',
            'home_currency' => 'sometimes|in:NGN,GBP,USD,EUR',
            'traveller_type' => 'sometimes|in:international,domestic,resident',
            'language' => 'sometimes|in:en,fr,yo,ig,ha,pcm',
            'accessibility' => 'sometimes|nullable|array',
        ]);
        $rider->update($data);

        return response()->json(['data' => $rider->fresh()]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $rider = $request->user();
        $rider->tokens()->delete();
        $rider->delete();

        return response()->json(['message' => 'Your account has been deleted.']);
    }

    public function contacts(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->emergencyContacts]);
    }

    public function storeContact(Request $request): JsonResponse
    {
        abort_if($request->user()->emergencyContacts()->count() >= 5, 422, 'You can add up to five emergency contacts.');
        $contact = $request->user()->emergencyContacts()->create($this->validateContact($request));

        return response()->json(['data' => $contact], 201);
    }

    public function updateContact(Request $request, EmergencyContact $contact): JsonResponse
    {
        abort_unless($contact->rider_id === $request->user()->id, 404);
        $contact->update($this->validateContact($request));

        return response()->json(['data' => $contact]);
    }

    public function destroyContact(Request $request, EmergencyContact $contact): JsonResponse
    {
        abort_unless($contact->rider_id === $request->user()->id, 404);
        $contact->delete();

        return response()->json(null, 204);
    }

    public function places(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->savedPlaces]);
    }

    public function storePlace(Request $request): JsonResponse
    {
        $place = $request->user()->savedPlaces()->create($this->validatePlace($request));

        return response()->json(['data' => $place], 201);
    }

    public function updatePlace(Request $request, SavedPlace $place): JsonResponse
    {
        abort_unless($place->rider_id === $request->user()->id, 404);
        $place->update($this->validatePlace($request));

        return response()->json(['data' => $place]);
    }

    public function destroyPlace(Request $request, SavedPlace $place): JsonResponse
    {
        abort_unless($place->rider_id === $request->user()->id, 404);
        $place->delete();

        return response()->json(null, 204);
    }

    private function validateContact(Request $request): array
    {
        return $request->validate([
            'name' => 'required|string|max:120',
            'phone' => 'required|string|max:32',
            'relationship' => 'nullable|string|max:60',
            'share_trips_automatically' => 'boolean',
        ]);
    }

    private function validatePlace(Request $request): array
    {
        return $request->validate([
            'label' => 'required|string|max:60',
            'address' => 'required|string|max:255',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);
    }
}
