<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use App\Services\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WalletController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $rider = $request->user();

        return response()->json(['data' => [
            'balance' => $rider->wallet_balance,
            'currency' => 'NGN',
            'loyalty_points' => $rider->loyalty_points,
            'referral_code' => $rider->referral_code,
            'recent' => $rider->transactions()->latest()->limit(5)->get(),
        ]]);
    }

    /**
     * Adds money to the wallet. In production this is called after the
     * card payment provider confirms the charge.
     */
    public function topUp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'amount' => 'required|integer|min:500|max:500000',
            'method' => 'required|in:card,bank_transfer',
        ]);
        $rider = $request->user();

        $tx = DB::transaction(function () use ($rider, $data) {
            $rider->increment('wallet_balance', $data['amount']);

            return Wallet::record($rider, 'wallet_topup', 'credit', $data['amount'], $data['method'], 'Wallet top-up');
        });

        return response()->json(['data' => ['balance' => $rider->fresh()->wallet_balance, 'transaction' => $tx]], 201);
    }

    public function transactions(Request $request): JsonResponse
    {
        return response()->json($request->user()->transactions()
            ->when($request->type, fn ($q, $t) => $q->where('type', $t))
            ->latest()->paginate(30));
    }

    public function validatePromo(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => 'required|string|max:32',
            'service' => 'required|in:ride,shuttle,tour',
            'amount' => 'nullable|integer|min:0',
        ]);
        $promo = PromoCode::where('code', strtoupper($data['code']))->first();
        $reason = $promo ? $promo->rejectionReason($data['service'], $request->user()) : 'That promo code does not exist.';

        if ($reason) {
            return response()->json(['valid' => false, 'message' => $reason], 422);
        }

        return response()->json([
            'valid' => true,
            'code' => $promo->code,
            'description' => $promo->description,
            'discount' => isset($data['amount']) ? $promo->discountFor($data['amount']) : null,
        ]);
    }
}
