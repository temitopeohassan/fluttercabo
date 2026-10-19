<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\DriverDocument;
use App\Models\Vehicle;
use App\Services\Wallet;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DriverController extends Controller
{
    public function index(Request $request): View
    {
        $drivers = Driver::query()->with('activeVehicle')
            ->when($request->q, fn ($q, $s) => $q->where(fn ($q) => $q->where('first_name', 'like', "%$s%")->orWhere('last_name', 'like', "%$s%")->orWhere('phone', 'like', "%$s%")->orWhereHas('vehicles', fn ($q) => $q->where('plate_number', 'like', "%$s%"))))
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->boolean('online'), fn ($q) => $q->where('is_online', true))
            ->withCount(['trips' => fn ($q) => $q->where('status', 'completed')])
            ->orderByRaw("case status when 'pending_review' then 0 else 1 end")->latest()
            ->paginate(25)->withQueryString();

        return view('admin.drivers.index', compact('drivers'));
    }

    public function show(Driver $driver): View
    {
        $driver->load('vehicles', 'documents.reviewer:id,name', 'fleetPartner');

        return view('admin.drivers.show', [
            'driver' => $driver,
            'blockers' => $driver->onlineBlockers(),
            'trips' => $driver->trips()->with('rider:id,first_name,last_name', 'rideType:id,name')->latest()->limit(15)->get(),
            'payouts' => $driver->payouts()->latest()->limit(8)->get(),
            'tickets' => $driver->supportTickets()->latest()->limit(5)->get(),
            'earnings30' => (int) $driver->trips()->where('status', 'completed')->where('completed_at', '>=', now()->subDays(30))->sum('driver_earnings'),
        ]);
    }

    public function status(Request $request, Driver $driver): RedirectResponse
    {
        $data = $request->validate([
            'status' => 'required|in:approved,suspended,rejected,pending_review',
            'reason' => 'nullable|required_if:status,suspended,rejected|string|max:255',
            'tier' => 'nullable|in:standard,premium',
        ]);

        $update = ['status' => $data['status'], 'status_reason' => $data['reason'] ?? null];
        if ($data['status'] === 'approved') {
            $update['approved_at'] = $driver->approved_at ?? now();
            $update['training_completed'] = true;
            $driver->vehicles()->where('status', 'pending')->update(['status' => 'approved']);
        } else {
            $update['is_online'] = false;
        }
        if (! empty($data['tier'])) {
            $update['tier'] = $data['tier'];
        }
        $driver->update($update);

        $driver->appNotifications()->create([
            'type' => 'account',
            'title' => match ($data['status']) {
                'approved' => 'You are approved to drive with Cabo',
                'suspended' => 'Your account has been suspended',
                'rejected' => 'Your application was not approved',
                default => 'Your account is under review',
            },
            'body' => $data['reason'] ?? ($data['status'] === 'approved' ? 'Go online whenever you are ready.' : 'Contact driver support for help.'),
        ]);

        return back()->with('status', "{$driver->name} is now ".humanize($data['status']).'.');
    }

    public function documents(Request $request): View
    {
        $documents = DriverDocument::with('driver:id,first_name,last_name,status', 'vehicle:id,plate_number')
            ->when($request->status ?? 'pending', fn ($q, $s) => $s === 'expiring'
                ? $q->where('status', 'approved')->whereBetween('expires_at', [today()->subYears(5), today()->addDays(30)])->orderBy('expires_at')
                : $q->where('status', $s)->latest())
            ->paginate(30)->withQueryString();

        return view('admin.drivers.documents', compact('documents'));
    }

    public function reviewDocument(Request $request, DriverDocument $document): RedirectResponse
    {
        $data = $request->validate([
            'status' => 'required|in:approved,rejected',
            'rejection_reason' => 'nullable|required_if:status,rejected|string|max:255',
            'expires_at' => 'nullable|date',
        ]);
        $document->update($data + ['reviewed_by' => $request->user()->id, 'reviewed_at' => now()]);

        if ($data['status'] === 'rejected') {
            $document->driver->appNotifications()->create([
                'type' => 'document', 'title' => $document->label.' needs a new upload', 'body' => $data['rejection_reason'],
            ]);
        }

        return back()->with('status', "{$document->label} ".$data['status'].'.');
    }

    public function downloadDocument(DriverDocument $document): StreamedResponse|RedirectResponse
    {
        if (! $document->file_path || ! Storage::disk('local')->exists($document->file_path)) {
            return back()->with('error', 'The file for this document is not on this server (sample data).');
        }

        return Storage::disk('local')->download($document->file_path);
    }

    public function reviewVehicle(Request $request, Vehicle $vehicle): RedirectResponse
    {
        $data = $request->validate([
            'status' => 'required|in:approved,rejected',
            'ride_types' => 'nullable|array',
            'ride_types.*' => 'exists:ride_types,code',
        ]);
        $vehicle->update(['status' => $data['status'], 'ride_types' => $data['ride_types'] ?? $vehicle->ride_types]);

        return back()->with('status', "Vehicle {$vehicle->plate_number} ".$data['status'].'.');
    }

    public function settleCash(Request $request, Driver $driver): RedirectResponse
    {
        $data = $request->validate(['amount' => 'required|integer|min:1|max:'.max(1, $driver->cash_commission_owed)]);
        $driver->decrement('cash_commission_owed', $data['amount']);
        Wallet::record($driver, 'cash_settlement', 'credit', $data['amount'], 'bank_transfer', 'Cash commission paid to Cabo', null, ['admin_id' => $request->user()->id]);

        return back()->with('status', naira($data['amount']).' of cash commission settled.');
    }
}
