@extends('admin.layout')
@section('title', 'Tour bookings')
@section('content')
<div class="page-head"><div><h1>Tour bookings</h1><p>Tickets sold through the rider app. Guests show a QR code at check-in.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Booking reference" aria-label="Search bookings">
        <select name="status" aria-label="Status">
            <option value="">Any status</option>
            @foreach (['confirmed', 'checked_in', 'completed', 'cancelled'] as $s)<option value="{{ $s }}" @selected(request('status') === $s)>{{ humanize($s) }}</option>@endforeach
        </select>
        @if (request('tour'))<input type="hidden" name="tour" value="{{ request('tour') }}">@endif
        <button class="btn btn-ghost" type="submit">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Booking</th><th>Tour</th><th>Date</th><th>Rider</th><th class="right">Guests</th><th class="right">Total</th><th>Payment</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($bookings as $b)
            <tr>
                <td><a class="strong mono" href="{{ route('admin.tour-bookings.show', $b) }}">{{ $b->reference }}</a></td>
                <td>{{ $b->tour->title }}</td>
                <td class="nowrap">{{ $b->slot->starts_at->format('D j M, H:i') }}</td>
                <td>{{ $b->rider->name }}</td>
                <td class="right">{{ $b->guests }}</td>
                <td class="right nowrap">{{ naira($b->total) }}</td>
                <td>{{ humanize($b->payment_method) }}<div class="small"><x-status :value="$b->payment_status" /></div></td>
                <td><x-status :value="$b->status" /></td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No bookings match.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $bookings->links() }}
</div>
@endsection
