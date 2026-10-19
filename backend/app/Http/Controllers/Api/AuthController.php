<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Rider;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Passwordless sign-in for both apps. The route passes "rider" or "driver",
 * and the issued token carries that as its only ability.
 */
class AuthController extends Controller
{
    public function __construct(private OtpService $otp) {}

    public function requestOtp(Request $request, string $app): JsonResponse
    {
        $request->validate(['identifier' => 'required|string|max:190']);
        [$identifier, $channel] = OtpService::normalise($request->identifier);
        $this->validateIdentifier($identifier, $channel);

        $code = $this->otp->send($app, $identifier, $channel);

        return response()->json(array_filter([
            'message' => $channel === 'sms' ? "We sent a 6-digit code to {$identifier}." : "We emailed a 6-digit code to {$identifier}.",
            'identifier' => $identifier,
            'channel' => $channel,
            'expires_in' => OtpService::TTL_MINUTES * 60,
            'debug_code' => app()->environment('production') ? null : $code,
        ]));
    }

    public function verify(Request $request, string $app): JsonResponse
    {
        $request->validate([
            'identifier' => 'required|string|max:190',
            'code' => 'required|digits:6',
            'device_name' => 'nullable|string|max:100',
            'referral_code' => 'nullable|string|max:16',
        ]);
        [$identifier, $channel] = OtpService::normalise($request->identifier);

        if (! $this->otp->verify($app, $identifier, $request->code)) {
            throw ValidationException::withMessages(['code' => 'That code is wrong or has expired.']);
        }

        $model = $app === 'rider' ? Rider::class : Driver::class;
        $column = $channel === 'sms' ? 'phone' : 'email';

        if ($app === 'driver' && $channel === 'email' && ! $model::where('email', $identifier)->exists()) {
            throw ValidationException::withMessages(['identifier' => 'Drivers sign up with a phone number.']);
        }

        $user = $model::firstOrNew([$column => $identifier]);
        $isNew = ! $user->exists;
        if ($isNew && $app === 'rider' && $request->referral_code) {
            $user->referred_by_id = Rider::where('referral_code', strtoupper($request->referral_code))->value('id');
        }
        if ($app === 'rider') {
            $user->last_active_at = now();
        }
        $user->save();

        if ($user->status === 'suspended') {
            return response()->json(['message' => 'Your account is suspended. Contact support for help.'], 403);
        }

        $token = $user->createToken($request->device_name ?? "{$app}-app", [$app])->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'is_new' => $isNew,
            $app => $user->fresh(),
        ], $isNew ? 201 : 200);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Signed out.']);
    }

    private function validateIdentifier(string $identifier, string $channel): void
    {
        $valid = $channel === 'email'
            ? filter_var($identifier, FILTER_VALIDATE_EMAIL) !== false
            : preg_match('/^\+\d{8,15}$/', $identifier) === 1;

        if (! $valid) {
            throw ValidationException::withMessages(['identifier' => 'Enter a valid phone number or email address.']);
        }
    }
}
