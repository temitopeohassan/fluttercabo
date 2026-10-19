@extends('admin.layout')
@section('title', 'Riders')
@section('content')
<div class="page-head"><div><h1>Riders</h1><p>Visitors and residents using the rider app.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Name, email or phone" aria-label="Search riders">
        <select name="type" aria-label="Traveller type">
            <option value="">All travellers</option>
            @foreach (['international', 'domestic', 'resident'] as $t)<option value="{{ $t }}" @selected(request('type') === $t)>{{ humanize($t) }}</option>@endforeach
        </select>
        <select name="status" aria-label="Status">
            <option value="">Any status</option>
            @foreach (['active', 'suspended'] as $s)<option value="{{ $s }}" @selected(request('status') === $s)>{{ humanize($s) }}</option>@endforeach
        </select>
        <button class="btn btn-ghost" type="submit">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Rider</th><th>Contact</th><th>Traveller</th><th class="right">Trips</th><th class="right">Tours</th><th class="right">Wallet</th><th>Rating</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($riders as $rider)
            <tr>
                <td><a class="strong" href="{{ route('admin.riders.show', $rider) }}">{{ $rider->name }}</a><div class="muted small">Joined {{ $rider->created_at->format('j M Y') }}</div></td>
                <td>{{ $rider->email }}<div class="muted small">{{ $rider->phone }}</div></td>
                <td>{{ humanize($rider->traveller_type) }}<div class="muted small">{{ $rider->nationality }} · {{ $rider->home_currency }}</div></td>
                <td class="right">{{ $rider->trips_count }}</td>
                <td class="right">{{ $rider->tour_bookings_count }}</td>
                <td class="right nowrap">{{ naira($rider->wallet_balance) }}</td>
                <td>{{ $rider->rating ? number_format($rider->rating, 2).' ★' : '—' }}</td>
                <td><x-status :value="$rider->status" /></td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No riders match.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $riders->links() }}
</div>
@endsection
