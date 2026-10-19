@extends('admin.layout')
@section('title', 'Shuttle '.$shuttle->reference)
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.shuttles.index') }}">Airport shuttles</a> / {{ $shuttle->reference }}</div>
<div class="page-head">
    <div class="row"><h1 class="mono" style="font-size:22px">{{ $shuttle->reference }}</h1><x-status :value="$shuttle->status" /><span class="muted">{{ $shuttle->direction === 'airport_pickup' ? 'Airport pickup' : 'Airport drop-off' }} · {{ $shuttle->rideType->name }}</span></div>
</div>
<div class="grid grid-main">
    <div class="card">
        <div class="card-head"><h2>Driver and flight</h2></div>
        <form class="card-body" method="post" action="{{ route('admin.shuttles.update', $shuttle) }}">
            @csrf @method('PUT')
            <div class="form-grid">
                <div class="field full">
                    <label for="driver_id">Driver</label>
                    <select id="driver_id" name="driver_id">
                        <option value="">Not assigned</option>
                        @foreach ($drivers as $d)
                            <option value="{{ $d->id }}" @selected($shuttle->driver_id === $d->id)>{{ $d->name }} · {{ $d->activeVehicle->description }} · {{ number_format($d->rating, 2) }} ★{{ $d->is_online ? ' · online' : '' }}</option>
                        @endforeach
                    </select>
                    <div class="hint">Only approved drivers whose car qualifies for {{ $shuttle->rideType->name }}.</div>
                </div>
                <div class="field"><label for="flight_time">Flight {{ $shuttle->direction === 'airport_pickup' ? 'arrives' : 'departs' }}</label><input id="flight_time" type="datetime-local" name="flight_time" value="{{ $shuttle->flight_time?->format('Y-m-d\TH:i') }}" required></div>
                <div class="field">
                    <label for="flight_status">Flight status</label>
                    <select id="flight_status" name="flight_status">
                        @foreach (['scheduled', 'on_time', 'delayed', 'landed', 'cancelled'] as $fs)<option value="{{ $fs }}" @selected($shuttle->flight_status === $fs)>{{ humanize($fs) }}</option>@endforeach
                    </select>
                </div>
                <div class="field"><label for="pickup_at">Pickup time</label><input id="pickup_at" type="datetime-local" name="pickup_at" value="{{ $shuttle->pickup_at->format('Y-m-d\TH:i') }}" required></div>
                <div class="field"><label for="meeting_point">Meeting point</label><input id="meeting_point" type="text" name="meeting_point" value="{{ $shuttle->meeting_point }}"></div>
            </div>
            <button class="btn btn-primary">Save</button>
        </form>
    </div>
    <div class="stack">
        <div class="card"><div class="card-body">
            <dl class="dl">
                <dt>Rider</dt><dd><a href="{{ route('admin.riders.show', $shuttle->rider) }}">{{ $shuttle->rider->name }}</a><div class="muted small">{{ $shuttle->rider->phone }}</div></dd>
                <dt>Flight</dt><dd>{{ $shuttle->flight_number }} · {{ $shuttle->terminal }}</dd>
                <dt>Airport</dt><dd>{{ $shuttle->airport }}</dd>
                <dt>{{ $shuttle->direction === 'airport_pickup' ? 'Drop-off' : 'Pickup' }}</dt><dd>{{ $shuttle->address }}</dd>
                <dt>Party</dt><dd>{{ $shuttle->passengers }} passengers · {{ $shuttle->large_bags }} large, {{ $shuttle->small_bags }} small bags</dd>
                @if ($shuttle->name_board)<dt>Name board</dt><dd class="mono">{{ $shuttle->name_board }}</dd>@endif
                @if ($shuttle->notes)<dt>Notes</dt><dd>{{ $shuttle->notes }}</dd>@endif
                <dt>Price</dt><dd>{{ naira($shuttle->price) }} · {{ humanize($shuttle->payment_method) }} <x-status :value="$shuttle->payment_status" /></dd>
                <dt>Driver payout</dt><dd>{{ naira($shuttle->driver_payout) }}</dd>
                <dt>Booked</dt><dd>{{ $shuttle->created_at->format('j M Y, H:i') }}</dd>
            </dl>
        </div></div>
        @unless (in_array($shuttle->status, ['completed', 'cancelled']))
        <div class="card"><div class="card-head"><h2>Cancel booking</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.shuttles.cancel', $shuttle) }}">
                @csrf
                <div class="field"><label class="check"><input type="checkbox" name="refund" value="1" checked> Refund {{ naira($shuttle->price) }} to the rider</label></div>
                <button class="btn btn-danger" onclick="return confirm('Cancel this airport booking?')">Cancel booking</button>
            </form>
        </div>
        @endunless
    </div>
</div>
@endsection
