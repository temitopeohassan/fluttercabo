@extends('admin.layout')
@section('title', 'Trips')
@section('content')
<div class="page-head"><div><h1>Trips</h1><p>Every ride requested in the rider app.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Reference or address" aria-label="Search trips">
        <select name="status" aria-label="Status">
            <option value="">Any status</option>
            <option value="active" @selected(request('status') === 'active')>Active now</option>
            @foreach (['scheduled', 'requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled', 'no_show'] as $s)<option value="{{ $s }}" @selected(request('status') === $s)>{{ humanize($s) }}</option>@endforeach
        </select>
        <select name="payment" aria-label="Payment method">
            <option value="">Any payment</option>
            @foreach (['card', 'wallet', 'bank_transfer', 'cash'] as $m)<option value="{{ $m }}" @selected(request('payment') === $m)>{{ humanize($m) }}</option>@endforeach
        </select>
        <input type="date" name="from" value="{{ request('from') }}" aria-label="From date">
        <input type="date" name="to" value="{{ request('to') }}" aria-label="To date">
        <button class="btn btn-ghost" type="submit">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Trip</th><th>Rider</th><th>Driver</th><th>Route</th><th>Type</th><th class="right">Fare</th><th>Payment</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($trips as $trip)
            <tr>
                <td><a class="strong mono" href="{{ route('admin.trips.show', $trip) }}">{{ $trip->reference }}</a><div class="muted small nowrap">{{ $trip->created_at->format('j M, H:i') }}</div></td>
                <td>{{ $trip->rider?->name }}</td>
                <td>{{ $trip->driver?->name ?? '—' }}</td>
                <td class="small">{{ Str::limit($trip->pickup_address, 28) }}<br><span class="muted">→ {{ Str::limit($trip->dropoff_address, 28) }}</span></td>
                <td>{{ $trip->rideType->name }}</td>
                <td class="right nowrap">{{ naira($trip->fare_total) }}@if ($trip->tip)<div class="muted small">+{{ naira($trip->tip) }} tip</div>@endif</td>
                <td>{{ humanize($trip->payment_method) }}<div class="small"><x-status :value="$trip->payment_status" /></div></td>
                <td><x-status :value="$trip->status" /></td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No trips match.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $trips->links() }}
</div>
@endsection
