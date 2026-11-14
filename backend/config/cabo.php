<?php

return [
    /*
    | Fixed sign-in code for the Guest and Host apps. While this is set, every
    | phone number and email signs in with it, so use it only until an SMS
    | provider is connected. Outside production it defaults to 123456; in
    | production it is off unless CABO_DEMO_OTP is set in .env.
    */
    'demo_otp' => env('CABO_DEMO_OTP', env('APP_ENV') === 'production' ? null : '123456') ?: null,
];
