<?php

namespace App\Services;

use App\Models\OtpCode;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

/**
 * Six-digit sign-in codes for the rider and driver apps. Codes expire after
 * ten minutes and allow five attempts. Delivery is logged until an SMS and
 * email provider is configured.
 */
class OtpService
{
    public const TTL_MINUTES = 10;

    public const MAX_ATTEMPTS = 5;

    /** @return string The plain code, returned to callers only outside production. */
    public function send(string $app, string $identifier, string $channel): string
    {
        $code = app()->environment('production') ? (string) random_int(100000, 999999) : (string) config('cabo.demo_otp', '123456');

        OtpCode::where('app', $app)->where('identifier', $identifier)->whereNull('used_at')->delete();
        OtpCode::create([
            'app' => $app,
            'identifier' => $identifier,
            'channel' => $channel,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(self::TTL_MINUTES),
        ]);

        Log::info("Cabo {$app} OTP for {$identifier} via {$channel}: {$code}");

        return $code;
    }

    public function verify(string $app, string $identifier, string $code): bool
    {
        $otp = OtpCode::where('app', $app)->where('identifier', $identifier)
            ->whereNull('used_at')->where('expires_at', '>', now())
            ->latest('id')->first();

        if (! $otp || $otp->attempts >= self::MAX_ATTEMPTS) {
            return false;
        }

        if (! Hash::check($code, $otp->code_hash)) {
            $otp->increment('attempts');

            return false;
        }

        $otp->update(['used_at' => now()]);

        return true;
    }

    public static function normalise(string $identifier): array
    {
        $identifier = trim($identifier);
        if (str_contains($identifier, '@')) {
            return [strtolower($identifier), 'email'];
        }

        $digits = preg_replace('/[^0-9+]/', '', $identifier);
        if (str_starts_with($digits, '0')) {
            $digits = '+234'.substr($digits, 1);
        } elseif (! str_starts_with($digits, '+')) {
            $digits = '+'.$digits;
        }

        return [$digits, 'sms'];
    }
}
