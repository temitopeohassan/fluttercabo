<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\Attraction;
use App\Models\Tour;
use App\Models\WishlistItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WishlistController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $items = $request->user()->wishlistItems()->with('item')->latest()->get()
            ->filter(fn ($i) => $i->item !== null)->values();

        return response()->json(['data' => $items]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => 'required|in:tour,attraction',
            'id' => 'required|integer',
        ]);
        $model = $data['type'] === 'tour' ? Tour::class : Attraction::class;
        $model::where('is_published', true)->findOrFail($data['id']);

        $item = $request->user()->wishlistItems()->firstOrCreate(['item_type' => $data['type'], 'item_id' => $data['id']]);

        return response()->json(['data' => $item->load('item')], $item->wasRecentlyCreated ? 201 : 200);
    }

    public function destroy(Request $request, WishlistItem $item): JsonResponse
    {
        abort_unless($item->rider_id === $request->user()->id, 404);
        $item->delete();

        return response()->json(null, 204);
    }
}
