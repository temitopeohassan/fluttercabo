<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SosAlert;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SosController extends Controller
{
    public function index(): View
    {
        return view('admin.sos.index', [
            'alerts' => SosAlert::with('raisedBy', 'trip.rider:id,first_name,last_name,phone', 'trip.driver:id,first_name,last_name,phone', 'handler:id,name')
                ->orderByRaw("case status when 'open' then 0 when 'acknowledged' then 1 else 2 end")->latest()->paginate(30),
        ]);
    }

    public function update(Request $request, SosAlert $alert): RedirectResponse
    {
        $data = $request->validate(['status' => 'required|in:acknowledged,resolved', 'notes' => 'nullable|string|max:2000']);
        $alert->update([
            'status' => $data['status'],
            'notes' => $data['notes'] ?? $alert->notes,
            'handled_by' => $request->user()->id,
            'acknowledged_at' => $alert->acknowledged_at ?? now(),
            'resolved_at' => $data['status'] === 'resolved' ? now() : null,
        ]);

        return back()->with('status', 'SOS alert '.$data['status'].'.');
    }
}
