<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\WaitlistSignup;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class WaitlistController extends Controller
{
    public function index(Request $request): View
    {
        $signups = WaitlistSignup::when($request->q, fn ($q, $s) => $q->where(fn ($q) => $q->where('name', 'like', "%$s%")->orWhere('email', 'like', "%$s%")))
            ->when($request->source, fn ($q, $s) => $q->where('source', $s))
            ->latest()->paginate(50)->withQueryString();

        return view('admin.waitlist.index', [
            'signups' => $signups,
            'total' => WaitlistSignup::count(),
            'invited' => WaitlistSignup::whereNotNull('invited_at')->count(),
            'sources' => WaitlistSignup::select('source')->distinct()->pluck('source'),
        ]);
    }

    public function export(): StreamedResponse
    {
        return response()->streamDownload(function () {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['name', 'email', 'source', 'signed_up_at', 'invited_at']);
            WaitlistSignup::orderBy('id')->each(fn ($s) => fputcsv($out, [$s->name, $s->email, $s->source, $s->created_at, $s->invited_at]));
            fclose($out);
        }, 'cabo-waitlist-'.today()->toDateString().'.csv', ['Content-Type' => 'text/csv']);
    }

    public function invite(WaitlistSignup $signup): RedirectResponse
    {
        $signup->update(['invited_at' => now()]);

        return back()->with('status', "{$signup->email} marked as invited.");
    }

    public function destroy(WaitlistSignup $signup): RedirectResponse
    {
        $signup->delete();

        return back()->with('status', 'Sign-up removed.');
    }
}
