<?php

namespace App\Providers;

use App\Models;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Short, stable names in polymorphic columns instead of class names.
        Relation::enforceMorphMap([
            'admin' => Models\Admin::class,
            'rider' => Models\Rider::class,
            'driver' => Models\Driver::class,
            'trip' => Models\Trip::class,
            'shuttle_booking' => Models\ShuttleBooking::class,
            'tour_booking' => Models\TourBooking::class,
            'tour' => Models\Tour::class,
            'attraction' => Models\Attraction::class,
            'payout' => Models\Payout::class,
        ]);

        Paginator::defaultView('admin.partials.pagination');

        // Work-queue counts shown next to the admin sidebar links.
        View::composer('admin.layout', function ($view) {
            $view->with('navCounts', [
                'sos' => Models\SosAlert::where('status', '!=', 'resolved')->count(),
                'applications' => Models\Driver::where('status', 'pending_review')->count(),
                'documents' => Models\DriverDocument::where('status', 'pending')->count(),
                'partners' => Models\Partner::where('status', 'pending')->count(),
                'shuttles' => Models\ShuttleBooking::where('status', 'confirmed')->whereNull('driver_id')->where('pickup_at', '>', now())->count(),
                'payouts' => Models\Payout::where('status', 'pending')->count(),
                'tickets' => Models\SupportTicket::where('status', 'open')->count(),
            ]);
        });
    }
}
