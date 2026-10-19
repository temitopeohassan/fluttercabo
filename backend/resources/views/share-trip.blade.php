<!DOCTYPE html>
<html lang="en-GB">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    @if (in_array($trip->status, \App\Models\Trip::ACTIVE_STATUSES))<meta http-equiv="refresh" content="30">@endif
    <title>Follow this Cabo ride</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="stylesheet" href="{{ asset('css/admin.css') }}?v=1">
</head>
<body>
<main class="content" style="max-width:560px;margin:0 auto">
    <img src="{{ asset('images/brand/logo-wordmark-dark.png') }}" alt="Cabo" width="107" height="40" style="margin:8px 0 20px">
    <div class="card">
        <div class="card-head"><h1 style="font-size:18px">{{ $trip->rider->first_name ?? 'Your contact' }} shared a ride with you</h1><x-status :value="$trip->status" /></div>
        <div class="card-body">
            <dl class="dl">
                <dt>From</dt><dd>{{ $trip->pickup_address }}</dd>
                <dt>To</dt><dd>{{ $trip->dropoff_address }}</dd>
                @if ($trip->driver)
                    <dt>Driver</dt><dd>{{ $trip->driver->first_name }} · {{ number_format($trip->driver->rating, 2) }} ★</dd>
                    <dt>Car</dt><dd>{{ $trip->vehicle?->colour }} {{ $trip->vehicle?->make }} {{ $trip->vehicle?->model }} · <span class="mono">{{ $trip->vehicle?->plate_number }}</span></dd>
                    @if ($trip->driver->current_lat && in_array($trip->status, \App\Models\Trip::ACTIVE_STATUSES))
                        <dt>Last seen</dt><dd><a href="https://maps.google.com/?q={{ $trip->driver->current_lat }},{{ $trip->driver->current_lng }}" target="_blank" rel="noopener">Open in Google Maps</a></dd>
                    @endif
                @endif
                @if ($trip->started_at)<dt>Started</dt><dd>{{ $trip->started_at->format('H:i') }}</dd>@endif
                @if ($trip->completed_at)<dt>Arrived</dt><dd>{{ $trip->completed_at->format('H:i') }}</dd>@endif
            </dl>
        </div>
    </div>
    <p class="muted small" style="margin-top:16px">If you think they are in danger, call 112. This page refreshes every 30 seconds while the ride is active.</p>
</main>
</body>
</html>
