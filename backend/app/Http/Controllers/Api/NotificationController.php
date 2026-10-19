<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json($user->appNotifications()->latest()->paginate(30)->toArray() + [
            'unread' => $user->appNotifications()->whereNull('read_at')->count(),
        ]);
    }

    public function read(Request $request, AppNotification $notification): JsonResponse
    {
        $user = $request->user();
        abort_unless($notification->recipient_type === $user->getMorphClass() && $notification->recipient_id === $user->id, 404);
        $notification->update(['read_at' => $notification->read_at ?? now()]);

        return response()->json(['data' => $notification]);
    }

    public function readAll(Request $request): JsonResponse
    {
        $request->user()->appNotifications()->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }
}
