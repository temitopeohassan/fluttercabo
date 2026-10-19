<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ShuttleBooking;
use App\Models\SupportTicket;
use App\Models\TourBooking;
use App\Models\Trip;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Help centre tickets for riders and drivers. */
class SupportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json($request->user()->supportTickets()->withCount('messages')->latest()->paginate(20));
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'category' => ['required', Rule::in(SupportTicket::CATEGORIES)],
            'subject' => 'required|string|max:150',
            'message' => 'required|string|max:5000',
            'trip_id' => 'nullable|integer',
            'shuttle_booking_id' => 'nullable|integer',
            'tour_booking_id' => 'nullable|integer',
        ]);

        $subject = null;
        $ownerColumn = $user->getMorphClass().'_id';
        if (! empty($data['trip_id'])) {
            $subject = Trip::where($ownerColumn, $user->id)->find($data['trip_id']);
        } elseif (! empty($data['shuttle_booking_id'])) {
            $subject = ShuttleBooking::where($ownerColumn, $user->id)->find($data['shuttle_booking_id']);
        } elseif (! empty($data['tour_booking_id']) && $ownerColumn === 'rider_id') {
            $subject = TourBooking::where('rider_id', $user->id)->find($data['tour_booking_id']);
        }

        $ticket = $user->supportTickets()->create([
            'category' => $data['category'], 'subject_line' => $data['subject'],
            'subject_type' => $subject?->getMorphClass(), 'subject_id' => $subject?->id,
            'priority' => in_array($data['category'], ['accident', 'vehicle_damage'], true) ? 'high' : 'normal',
        ]);
        $ticket->messages()->create(['sender_type' => $user->getMorphClass(), 'sender_id' => $user->id, 'body' => $data['message']]);

        return response()->json(['data' => $ticket->load('messages')], 201);
    }

    public function show(Request $request, SupportTicket $ticket): JsonResponse
    {
        $this->authorizeTicket($request, $ticket);

        return response()->json(['data' => $ticket->load('messages', 'subject')]);
    }

    public function reply(Request $request, SupportTicket $ticket): JsonResponse
    {
        $this->authorizeTicket($request, $ticket);
        $data = $request->validate(['message' => 'required|string|max:5000']);
        $user = $request->user();

        $message = $ticket->messages()->create(['sender_type' => $user->getMorphClass(), 'sender_id' => $user->id, 'body' => $data['message']]);
        $ticket->update(['status' => $ticket->status === 'resolved' || $ticket->status === 'awaiting_user' ? 'open' : $ticket->status, 'resolved_at' => null]);

        return response()->json(['data' => $message], 201);
    }

    private function authorizeTicket(Request $request, SupportTicket $ticket): void
    {
        $user = $request->user();
        abort_unless($ticket->requester_type === $user->getMorphClass() && $ticket->requester_id === $user->id, 404);
    }
}
