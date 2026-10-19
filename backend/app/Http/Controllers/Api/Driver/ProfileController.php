<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\DriverDocument;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $driver = $request->user()->load('activeVehicle', 'fleetPartner:id,name');

        return response()->json(['data' => $driver->toArray() + [
            'online_blockers' => $driver->onlineBlockers(),
            'documents_summary' => $this->documentsSummary($driver),
        ]]);
    }

    /** Sign-up and profile details. Bank details and personal info lock once approved. */
    public function update(Request $request): JsonResponse
    {
        $driver = $request->user();
        $data = $request->validate([
            'first_name' => 'sometimes|required|string|max:80',
            'last_name' => 'sometimes|required|string|max:80',
            'email' => ['sometimes', 'nullable', 'email', 'max:190', Rule::unique('drivers')->ignore($driver->id)],
            'date_of_birth' => 'sometimes|date|before:-21 years',
            'address' => 'sometimes|string|max:255',
            'photo_url' => 'sometimes|nullable|url|max:255',
            'languages' => 'sometimes|array',
            'languages.*' => 'string|max:30',
            'driver_type' => 'sometimes|in:independent,fleet',
            'fleet_partner_id' => 'sometimes|nullable|exists:fleet_partners,id',
            'background_check_consent' => 'sometimes|accepted',
            'bank_name' => 'sometimes|string|max:60',
            'bank_account_number' => 'sometimes|digits:10',
            'bank_account_name' => 'sometimes|string|max:120',
            'preferences' => 'sometimes|array',
            'preferences.ride_types' => 'array',
            'preferences.jobs' => 'array',
            'preferences.destination_filter' => 'nullable|array',
        ]);

        if ($driver->status === 'approved') {
            unset($data['date_of_birth'], $data['driver_type'], $data['fleet_partner_id']);
        }
        $driver->update($data);

        return response()->json(['data' => $driver->fresh()]);
    }

    /** Applicant has finished the forms and uploaded documents: move to review. */
    public function submit(Request $request): JsonResponse
    {
        $driver = $request->user();
        if ($driver->status !== 'applicant') {
            throw ValidationException::withMessages(['status' => 'Your application has already been submitted.']);
        }
        $missing = collect(Driver::REQUIRED_DOCUMENTS)
            ->reject(fn ($t) => $driver->documents()->where('type', $t)->exists())
            ->map(fn ($t) => DriverDocument::label($t));
        if (! $driver->first_name || ! $driver->bank_account_number || ! $driver->background_check_consent) {
            $missing->prepend('Personal details, bank details and background check consent');
        }
        if (! $driver->vehicles()->exists()) {
            $missing->push('Vehicle details');
        }
        if ($missing->isNotEmpty()) {
            throw ValidationException::withMessages(['documents' => 'Still needed: '.$missing->implode(', ').'.']);
        }

        $driver->update(['status' => 'pending_review']);

        return response()->json(['data' => $driver, 'message' => 'Application submitted. We will review it within 48 hours.']);
    }

    public function documents(Request $request): JsonResponse
    {
        $driver = $request->user();

        return response()->json(['data' => $driver->documents()->latest()->get(), 'summary' => $this->documentsSummary($driver)]);
    }

    public function uploadDocument(Request $request): JsonResponse
    {
        $driver = $request->user();
        $data = $request->validate([
            'type' => ['required', Rule::in(array_keys(DriverDocument::TYPES))],
            'file' => 'required|file|mimes:jpg,jpeg,png,pdf|max:8192',
            'expires_at' => 'nullable|date|after:today',
            'vehicle_id' => ['nullable', Rule::exists('vehicles', 'id')->where('driver_id', $driver->id)],
        ]);

        $path = $request->file('file')->store("documents/driver-{$driver->id}", 'local');
        $document = $driver->documents()->updateOrCreate(['type' => $data['type'], 'vehicle_id' => $data['vehicle_id'] ?? null], [
            'label' => DriverDocument::label($data['type']),
            'file_path' => $path,
            'status' => 'pending',
            'rejection_reason' => null,
            'expires_at' => $data['expires_at'] ?? null,
            'reviewed_by' => null,
            'reviewed_at' => null,
        ]);

        return response()->json(['data' => $document], 201);
    }

    public function vehicles(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->vehicles]);
    }

    public function storeVehicle(Request $request): JsonResponse
    {
        $data = $request->validate([
            'make' => 'required|string|max:40',
            'model' => 'required|string|max:40',
            'year' => 'required|integer|min:'.(now()->year - 15).'|max:'.(now()->year + 1),
            'colour' => 'required|string|max:30',
            'plate_number' => 'required|string|max:16|unique:vehicles,plate_number',
            'seats' => 'required|integer|min:4|max:8',
            'wheelchair_accessible' => 'boolean',
        ]);
        $data['plate_number'] = strtoupper($data['plate_number']);
        $driver = $request->user();
        $vehicle = $driver->vehicles()->create($data + ['is_active' => ! $driver->vehicles()->exists()]);

        return response()->json(['data' => $vehicle], 201);
    }

    /** Switch which approved vehicle the driver is using today. */
    public function activateVehicle(Request $request, Vehicle $vehicle): JsonResponse
    {
        $driver = $request->user();
        abort_unless($vehicle->driver_id === $driver->id, 404);
        if ($vehicle->status !== 'approved') {
            throw ValidationException::withMessages(['vehicle' => 'This vehicle has not been approved yet.']);
        }
        if ($driver->is_online) {
            throw ValidationException::withMessages(['vehicle' => 'Go offline before switching vehicles.']);
        }
        $driver->vehicles()->update(['is_active' => false]);
        $vehicle->update(['is_active' => true]);

        return response()->json(['data' => $vehicle]);
    }

    /** Go online or offline. Blocked while the account or documents are not in order. */
    public function status(Request $request): JsonResponse
    {
        $driver = $request->user();
        $data = $request->validate([
            'online' => 'required|boolean',
            'lat' => 'required_if:online,true|nullable|numeric|between:-90,90',
            'lng' => 'required_if:online,true|nullable|numeric|between:-180,180',
        ]);

        if ($data['online']) {
            $blockers = $driver->onlineBlockers();
            if ($blockers) {
                return response()->json(['message' => 'You cannot go online yet.', 'blockers' => $blockers], 403);
            }
            $driver->update(['is_online' => true, 'current_lat' => $data['lat'], 'current_lng' => $data['lng'], 'location_updated_at' => now()]);
        } else {
            $driver->update(['is_online' => false]);
        }

        return response()->json(['data' => ['is_online' => $driver->is_online]]);
    }

    public function location(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);
        $request->user()->update(['current_lat' => $data['lat'], 'current_lng' => $data['lng'], 'location_updated_at' => now()]);

        return response()->json(['data' => ['updated' => true]]);
    }

    private function documentsSummary(Driver $driver): array
    {
        $docs = $driver->documents()->get();

        return [
            'approved' => $docs->where('status', 'approved')->count(),
            'pending' => $docs->where('status', 'pending')->count(),
            'rejected' => $docs->where('status', 'rejected')->count(),
            'expiring_soon' => $docs->filter(fn ($d) => $d->expires_at && $d->expires_at->between(now(), now()->addDays(30)))->values(),
            'expired' => $docs->filter(fn ($d) => $d->isExpired())->values(),
        ];
    }
}
