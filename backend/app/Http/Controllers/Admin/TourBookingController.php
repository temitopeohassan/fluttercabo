<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TourBooking;
use App\Services\Wallet;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class TourBookingController extends Controller
{
    public function index(Request $request): View
    {
        $bookings = TourBooking::with('rider:id,first_name,last_name', 'tour:id,title', 'slot:id,starts_at')
            ->when($request->q, fn ($q, $s) => $q->where('reference', 'like', "%$s%"))
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->tour, fn ($q, $t) => $q->where('tour_id', $t))
            ->latest()->paginate(30)->withQueryString();

        return view('admin.tour-bookings.index', compact('bookings'));
    }

    public function show(TourBooking $booking): View
    {
        return view('admin.tour-bookings.show', ['booking' => $booking->load('rider', 'tour.partner', 'slot.guide', 'promoCode', 'review')]);
    }

    public function checkIn(TourBooking $booking): RedirectResponse
    {
        abort_unless($booking->status === 'confirmed', 422);
        $booking->update(['status' => 'checked_in', 'checked_in_at' => now()]);

        return back()->with('status', 'Guest checked in.');
    }

    public function cancel(Request $request, TourBooking $booking): RedirectResponse
    {
        abort_unless(in_array($booking->status, ['confirmed', 'checked_in'], true), 422);
        $data = $request->validate(['refund_amount' => 'required|integer|min:0|max:'.$booking->total]);

        DB::transaction(function () use ($booking, $data) {
            $booking->update([
                'status' => 'cancelled', 'cancelled_at' => now(), 'refund_amount' => $data['refund_amount'],
                'payment_status' => $data['refund_amount'] === $booking->total ? 'refunded' : ($data['refund_amount'] > 0 ? 'partially_refunded' : 'paid'),
            ]);
            $booking->slot()->decrement('booked', $booking->guests);
            Wallet::refund($booking->rider, $data['refund_amount'], $booking->payment_method, "Refund for {$booking->reference}", $booking);
        });

        return back()->with('status', 'Booking cancelled. '.naira($data['refund_amount']).' refunded.');
    }

    public function toggleReview(TourBooking $booking): RedirectResponse
    {
        $review = $booking->review;
        abort_unless($review, 404);
        $review->update(['is_visible' => ! $review->is_visible]);
        $booking->tour->refreshRating();

        return back()->with('status', $review->is_visible ? 'Review shown.' : 'Review hidden.');
    }
}
