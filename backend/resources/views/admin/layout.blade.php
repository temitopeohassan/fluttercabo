<!DOCTYPE html>
<html lang="en-GB">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>@yield('title', 'Dashboard') · Cabo Control Panel</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="stylesheet" href="{{ asset('css/admin.css') }}?v=1">
</head>
<body>
@php
    $admin = auth()->user();
    $nav = [
        'Overview' => [
            ['admin.dashboard', 'Dashboard', 'home', null, 'admin.dashboard'],
            ['admin.sos.index', 'SOS alerts', 'alert', $navCounts['sos'] ?? 0, 'admin.sos.*', true],
        ],
        'People' => [
            ['admin.riders.index', 'Riders', 'users', null, 'admin.riders.*'],
            ['admin.drivers.index', 'Drivers', 'car', $navCounts['applications'] ?? 0, 'admin.drivers.*'],
            ['admin.documents.index', 'Documents', 'file', $navCounts['documents'] ?? 0, 'admin.documents.*'],
            ['admin.partners.index', 'Partners', 'briefcase', $navCounts['partners'] ?? 0, 'admin.partners.*'],
        ],
        'Operations' => [
            ['admin.trips.index', 'Trips', 'route', null, 'admin.trips.*'],
            ['admin.shuttles.index', 'Airport shuttles', 'plane', $navCounts['shuttles'] ?? 0, 'admin.shuttles.*'],
            ['admin.tours.index', 'Tours', 'map', null, 'admin.tours.*'],
            ['admin.tour-bookings.index', 'Tour bookings', 'ticket', null, 'admin.tour-bookings.*'],
            ['admin.attractions.index', 'Attractions', 'pin', null, 'admin.attractions.*'],
        ],
        'Money' => [
            ['admin.pricing.index', 'Pricing & zones', 'chart', null, 'admin.pricing.*'],
            ['admin.promo-codes.index', 'Promo codes', 'tag', null, 'admin.promo-codes.*'],
            ['admin.payouts.index', 'Payouts', 'wallet', $navCounts['payouts'] ?? 0, 'admin.payouts.*'],
            ['admin.transactions.index', 'Transactions', 'list', null, 'admin.transactions.*'],
        ],
        'Customers' => [
            ['admin.support.index', 'Support', 'chat', $navCounts['tickets'] ?? 0, 'admin.support.*'],
            ['admin.waitlist.index', 'Waitlist', 'mail', null, 'admin.waitlist.*'],
        ],
    ];
    if ($admin->isSuperAdmin()) {
        $nav['System'] = [
            ['admin.settings', 'Settings', 'settings', null, 'admin.settings'],
            ['admin.admins.index', 'Admin users', 'shield', null, 'admin.admins.*'],
        ];
    }
@endphp
<div class="shell">
    <aside class="sidebar" id="sidebar">
        <a class="brand" href="{{ route('admin.dashboard') }}"><img src="{{ asset('images/brand/logo-lockup-light.png') }}" alt="Cabo: Ride, Tour, Travel" width="103" height="44"></a>
        <nav class="nav" aria-label="Main">
            @foreach ($nav as $group => $items)
                <div class="nav-group">
                    <div class="nav-group-title">{{ $group }}</div>
                    @foreach ($items as $item)
                        <a href="{{ route($item[0]) }}" @class(['active' => request()->routeIs($item[4])])>
                            <x-icon :name="$item[2]" /> {{ $item[1] }}
                            @if ($item[3])<span @class(['count', 'alert' => $item[5] ?? false])>{{ $item[3] }}</span>@endif
                        </a>
                    @endforeach
                </div>
            @endforeach
        </nav>
    </aside>

    <div class="main">
        <header class="topbar">
            <button class="menu-toggle" type="button" aria-label="Open menu" onclick="document.body.classList.toggle('nav-open')"><x-icon name="menu" width="22" height="22" /></button>
            <form class="search" action="{{ route('admin.trips.index') }}" method="get" role="search">
                <input type="search" name="q" placeholder="Search trip reference…" aria-label="Search trips by reference" value="{{ request()->routeIs('admin.trips.index') ? request('q') : '' }}">
            </form>
            <div class="who">
                <div class="right who-name">
                    <div class="strong">{{ $admin->name }}</div>
                    <div class="muted small">{{ humanize($admin->role) }}</div>
                </div>
                <a class="avatar" href="{{ route('admin.account') }}" title="Your account" style="text-decoration:none">{{ strtoupper(substr($admin->name, 0, 1)) }}</a>
                <form method="post" action="{{ route('admin.logout') }}">
                    @csrf
                    <button class="btn btn-ghost btn-sm" type="submit"><x-icon name="logout" width="16" height="16" /> Sign out</button>
                </form>
            </div>
        </header>

        <main class="content">
            @if (($navCounts['sos'] ?? 0) > 0 && ! request()->routeIs('admin.sos.*'))
                <a class="sos-banner" href="{{ route('admin.sos.index') }}"><x-icon name="alert" width="20" height="20" /> {{ $navCounts['sos'] }} open SOS {{ Str::plural('alert', $navCounts['sos']) }}. Respond now.</a>
            @endif
            @if (session('status'))
                <div class="flash ok" role="status">{{ session('status') }}</div>
            @endif
            @if (session('error'))
                <div class="flash err" role="alert">{{ session('error') }}</div>
            @endif
            @if ($errors->any())
                <div class="flash err" role="alert">
                    Please fix the following:
                    <ul>@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
                </div>
            @endif
            @yield('content')
        </main>
    </div>
</div>
</body>
</html>
