<?php

namespace App\Services;

use App\Models\OtpCode;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Six-digit sign-in codes for the Guest and Host apps. Codes expire after
 * ten minutes and allow five attempts.
 *
 * Email codes are sent with the configured mailer. SMS codes are only
 * written to the log until an SMS provider is connected; until then set
 * CABO_DEMO_OTP so the apps can sign in with a fixed code.
 */
class OtpService
{
    public const TTL_MINUTES = 10;

    public const MAX_ATTEMPTS = 5;

    /** The fixed demo code, or null when real codes are in use. */
    public static function demoCode(): ?string
    {
        $code = config('cabo.demo_otp');

        return $code ? (string) $code : null;
    }

    /** @return string The plain code. Callers only reveal it in demo mode. */
    public function send(string $app, string $identifier, string $channel): string
    {
        $code = self::demoCode() ?? (string) random_int(100000, 999999);

        OtpCode::where('app', $app)->where('identifier', $identifier)->whereNull('used_at')->delete();
        OtpCode::create([
            'app' => $app,
            'identifier' => $identifier,
            'channel' => $channel,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(self::TTL_MINUTES),
        ]);

        if (self::demoCode() === null && $channel === 'email') {
            try {
                Mail::raw(
                    "Your Cabo sign-in code is {$code}. It expires in ".self::TTL_MINUTES." minutes. If you did not ask for it, ignore this email.",
                    fn ($message) => $message->to($identifier)->subject("{$code} is your Cabo sign-in code"),
                );
            } catch (Throwable $e) {
                Log::error("Could not email the sign-in code to {$identifier}: {$e->getMessage()}");
            }
        }

        // Until an SMS provider is connected this log line is the only way to read an SMS code.
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
