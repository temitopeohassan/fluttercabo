<!DOCTYPE html>
<html lang="en-GB">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>Sign in · Cabo Control Panel</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="stylesheet" href="{{ asset('css/admin.css') }}?v=1">
</head>
<body>
<div class="auth">
    <div class="auth-art" role="img" aria-label="Lekki–Ikoyi Link Bridge at sunset">
        <div class="copy">
            <h2>Lagos, <span>handled.</span></h2>
            <p>Rides, airport shuttles and tours for visitors, run from one control panel.</p>
        </div>
    </div>
    <div class="auth-form">
        <form method="post" action="{{ route('admin.login') }}">
            @csrf
            <img class="logo" src="{{ asset('images/brand/logo-wordmark-dark.png') }}" alt="Cabo" width="129" height="48">
            <h1>Control panel</h1>
            <p class="muted" style="margin:4px 0 24px">Sign in with your Cabo admin account.</p>

            @if ($errors->any())
                <div class="flash err" role="alert">{{ $errors->first() }}</div>
            @endif

            <div class="field">
                <label for="email">Email</label>
                <input id="email" type="email" name="email" value="{{ old('email') }}" autocomplete="username" required autofocus>
            </div>
            <div class="field">
                <label for="password">Password</label>
                <input id="password" type="password" name="password" autocomplete="current-password" required>
            </div>
            <div class="field">
                <label class="check"><input type="checkbox" name="remember" value="1"> Keep me signed in</label>
            </div>
            <button class="btn btn-primary btn-block" type="submit">Sign in</button>
        </form>
    </div>
</div>
</body>
</html>
