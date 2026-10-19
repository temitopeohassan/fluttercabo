<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\DriverDocument;
use App\Models\Payout;
use App\Models\Rider;
use App\Models\ShuttleBooking;
use App\Models\SosAlert;
use App\Models\SupportTicket;
use App\Models\TourBooking;
use App\Models\Trip;
use App\Models\WaitlistSignup;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        $completed = Trip::where('status', 'completed');
        $last30 = (clone $completed)->where('completed_at', '>=', now()->subDays(30));

        $daily = (clone $last30)->get(['completed_at', 'fare_total'])
            ->groupBy(fn ($t) => $t->completed_at->toDateString());
        $chart = collect(range(13, 0))->map(function ($ago) use ($daily) {
            $date = today()->subDays($ago)->toDateString();

            return ['date' => $date, 'trips' => isset($daily[$date]) ? $daily[$date]->count() : 0, 'gmv' => isset($daily[$date]) ? (int) $daily[$date]->sum('fare_total') : 0];
        });

        return view('admin.dashboard', [
            'stats' => [
                'trips_today' => (clone $completed)->whereDate('completed_at', today())->count(),
                'active_trips' => Trip::whereIn('status', Trip::ACTIVE_STATUSES)->count(),
                'gmv_30' => (int) (clone $last30)->sum('fare_total'),
                'commission_30' => (int) (clone $last30)->sum('commission'),
                'tour_revenue_30' => (int) TourBooking::where('created_at', '>=', now()->subDays(30))->where('status', '!=', 'cancelled')->sum('total'),
                'riders' => Rider::count(),
                'new_riders_7' => Rider::where('created_at', '>=', now()->subDays(7))->count(),
                'drivers_online' => Driver::where('is_online', true)->count(),
                'drivers_approved' => Driver::where('status', 'approved')->count(),
                'waitlist' => WaitlistSignup::count(),
            ],
            'queues' => [
                'sos' => SosAlert::where('status', '!=', 'resolved')->count(),
                'applications' => Driver::where('status', 'pending_review')->count(),
                'documents' => DriverDocument::where('status', 'pending')->count(),
                'tickets' => SupportTicket::whereIn('status', ['open', 'in_review'])->count(),
                'payouts' => Payout::whereIn('status', ['pending', 'processing'])->count(),
                'shuttles_unassigned' => ShuttleBooking::where('status', 'confirmed')->whereNull('driver_id')->where('pickup_at', '>', now())->count(),
                'expiring_documents' => DriverDocument::where('status', 'approved')->whereBetween('expires_at', [today(), today()->addDays(30)])->count(),
            ],
            'chart' => $chart,
            'openSos' => SosAlert::where('status', '!=', 'resolved')->with('raisedBy', 'trip')->latest()->get(),
            'recentTrips' => Trip::with('rider:id,first_name,last_name', 'driver:id,first_name,last_name', 'rideType:id,name')->latest()->limit(8)->get(),
            'upcomingShuttles' => ShuttleBooking::where('pickup_at', '>', now())->whereIn('status', ['confirmed', 'driver_assigned'])->with('rider:id,first_name,last_name', 'driver:id,first_name,last_name')->orderBy('pickup_at')->limit(5)->get(),
        ]);
    }
}
