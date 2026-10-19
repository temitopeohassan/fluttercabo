@extends('admin.layout')
@section('title', 'Trip '.$trip->reference)
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.trips.index') }}">Trips</a> / {{ $trip->reference }}</div>
<div class="page-head">
    <div class="row"><h1 class="mono" style="font-size:22px">{{ $trip->reference }}</h1><x-status :value="$trip->status" /><span class="muted">{{ $trip->rideType->name }} · requested {{ $trip->created_at->format('D j M Y, H:i') }}</span></div>
</div>

<div class="grid grid-main">
    <div class="stack">
        <div class="card">
            <div class="card-head"><h2>Route</h2><span class="muted">{{ $trip->distance_km }} km · {{ $trip->duration_minutes }} min</span></div>
            <div class="card-body">
                <ol class="steps">
                    <li><span class="strong">Pickup</span>: {{ $trip->pickup_address }} <span class="muted small">({{ $trip->pickup_lat }}, {{ $trip->pickup_lng }})</span></li>
                    @foreach ($trip->stops ?? [] as $stop)
                        <li><span class="strong">Stop</span>: {{ $stop['address'] }}</li>
                    @endforeach
                    <li><span class="strong">Drop-off</span>: {{ $trip->dropoff_address }} <span class="muted small">({{ $trip->dropoff_lat }}, {{ $trip->dropoff_lng }})</span></li>
                </ol>
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Timeline</h2></div>
            <div class="card-body">
                <dl class="dl">
                    @if ($trip->scheduled_at)<dt>Scheduled for</dt><dd>{{ $trip->scheduled_at->format('D j M, H:i') }}</dd>@endif
                    <dt>Requested</dt><dd>{{ $trip->created_at->format('H:i:s') }}</dd>
                    <dt>Accepted</dt><dd>{{ $trip->accepted_at?->format('H:i:s') ?? '—' }}</dd>
                    <dt>Driver arrived</dt><dd>{{ $trip->arrived_at?->format('H:i:s') ?? '—' }}</dd>
                    <dt>Started (PIN)</dt><dd>{{ $trip->started_at?->format('H:i:s') ?? '—' }}</dd>
                    <dt>Completed</dt><dd>{{ $trip->completed_at?->format('H:i:s') ?? '—' }}</dd>
                    @if ($trip->cancelled_at)<dt>Cancelled</dt><dd>{{ $trip->cancelled_at->format('H:i:s') }} by {{ $trip->cancelled_by }}: {{ $trip->cancellation_reason }}</dd>@endif
                </dl>
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Payments</h2></div>
            @include('admin.partials.transactions', ['transactions' => $trip->transactions->sortByDesc('id')])
        </div>
        @if ($trip->driver_rating || $trip->rider_rating)
        <div class="card"><div class="card-head"><h2>Ratings</h2></div><div class="card-body">
            <dl class="dl">
                <dt>Rider rated driver</dt><dd>{{ $trip->driver_rating ? $trip->driver_rating.' ★' : '—' }} {{ $trip->driver_feedback }}</dd>
                <dt>Driver rated rider</dt><dd>{{ $trip->rider_rating ? $trip->rider_rating.' ★' : '—' }} {{ $trip->rider_feedback }}</dd>
            </dl>
        </div></div>
        @endif
    </div>
    <div class="stack">
        <div class="card"><div class="card-head"><h2>Fare</h2><x-status :value="$trip->payment_status" /></div><div class="card-body">
            <dl class="dl">
                <dt>Base</dt><dd>{{ naira($trip->fare_base) }}</dd>
                <dt>Distance</dt><dd>{{ naira($trip->fare_distance) }}</dd>
                <dt>Time</dt><dd>{{ naira($trip->fare_time) }}</dd>
                @if ($trip->surge_multiplier > 1)<dt>Surge</dt><dd>× {{ $trip->surge_multiplier }}</dd>@endif
                @if ($trip->fare_stops)<dt>Stops</dt><dd>{{ naira($trip->fare_stops) }}</dd>@endif
                @if ($trip->tolls)<dt>Tolls</dt><dd>{{ naira($trip->tolls) }}</dd>@endif
                @if ($trip->discount)<dt>Discount</dt><dd>−{{ naira($trip->discount) }} {{ $trip->promoCode?->code }}</dd>@endif
                <dt class="strong">Total</dt><dd class="strong">{{ naira($trip->fare_total) }}</dd>
                @if ($trip->tip)<dt>Tip</dt><dd>{{ naira($trip->tip) }}</dd>@endif
                @if ($trip->cancellation_fee)<dt>Cancellation fee</dt><dd>{{ naira($trip->cancellation_fee) }}</dd>@endif
                <dt>Commission</dt><dd>{{ naira($trip->commission) }}</dd>
                <dt>Driver earned</dt><dd>{{ naira($trip->driver_earnings) }}</dd>
                <dt>Method</dt><dd>{{ humanize($trip->payment_method) }}</dd>
                <dt>Rider PIN</dt><dd class="mono">{{ $trip->pin }}</dd>
            </dl>
        </div></div>
        <div class="card"><div class="card-head"><h2>People</h2></div><div class="card-body">
            <dl class="dl">
                <dt>Rider</dt><dd><a href="{{ route('admin.riders.show', $trip->rider) }}">{{ $trip->rider->name }}</a><div class="muted small">{{ $trip->rider->phone }}</div></dd>
                <dt>Driver</dt><dd>@if ($trip->driver)<a href="{{ route('admin.drivers.show', $trip->driver) }}">{{ $trip->driver->name }}</a><div class="muted small">{{ $trip->driver->phone }}</div>@else — @endif</dd>
                <dt>Vehicle</dt><dd>{{ $trip->vehicle ? $trip->vehicle->description : '—' }}<div class="muted small mono">{{ $trip->vehicle?->plate_number }}</div></dd>
            </dl>
        </div></div>
        @if (in_array($trip->status, ['scheduled', 'requested', 'accepted', 'arrived', 'in_progress']))
        <div class="card"><div class="card-head"><h2>Cancel trip</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.trips.cancel', $trip) }}">
                @csrf
                <div class="field"><label for="reason">Reason</label><input id="reason" type="text" name="reason" required></div>
                <button class="btn btn-danger" onclick="return confirm('Cancel this trip? No fee is charged when an admin cancels.')">Cancel trip</button>
            </form>
        </div>
        @endif
        @if ($trip->payment_status !== 'refunded' && ($trip->fare_total + $trip->tip + $trip->cancellation_fee) > 0 && in_array($trip->status, ['completed', 'cancelled', 'no_show']))
        <div class="card"><div class="card-head"><h2>Refund</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.trips.refund', $trip) }}">
                @csrf
                <div class="field"><label for="amount">Amount (₦)</label><input id="amount" type="number" name="amount" min="1" max="{{ $trip->fare_total + $trip->tip + $trip->cancellation_fee }}" required></div>
                <div class="field"><label for="refund-reason">Reason</label><input id="refund-reason" type="text" name="reason" placeholder="e.g. Driver took a longer route" required></div>
                <div class="field"><label class="check"><input type="checkbox" name="to_wallet" value="1" checked> Refund to Cabo wallet (instant)</label></div>
                <button class="btn btn-ghost">Issue refund</button>
            </form>
        </div>
        @endif
    </div>
</div>
@endsection
