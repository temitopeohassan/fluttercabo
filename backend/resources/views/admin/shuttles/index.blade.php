@extends('admin.layout')
@section('title', 'Airport shuttles')
@section('content')
<div class="page-head"><div><h1>Airport shuttles</h1><p>Fixed-price pickups and drop-offs at Murtala Muhammed International. Assign a driver at least a day ahead.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <nav class="tabs" aria-label="When">
            <a href="{{ route('admin.shuttles.index', ['status' => request('status')]) }}" @class(['active' => request('when') !== 'past'])>Upcoming</a>
            <a href="{{ route('admin.shuttles.index', ['when' => 'past', 'status' => request('status')]) }}" @class(['active' => request('when') === 'past'])>Past</a>
        </nav>
        <input type="hidden" name="when" value="{{ request('when') }}">
        <select name="status" aria-label="Status" onchange="this.form.submit()">
            <option value="">Any status</option>
            @foreach (['confirmed' => 'Needs a driver', 'driver_assigned' => 'Driver assigned', 'in_progress' => 'In progress', 'completed' => 'Completed', 'cancelled' => 'Cancelled'] as $s => $label)<option value="{{ $s }}" @selected(request('status') === $s)>{{ $label }}</option>@endforeach
        </select>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Booking</th><th>Pickup time</th><th>Flight</th><th>Rider</th><th>Address</th><th>Car</th><th>Driver</th><th class="right">Price</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($shuttles as $s)
            <tr>
                <td><a class="strong mono" href="{{ route('admin.shuttles.show', $s) }}">{{ $s->reference }}</a><div class="muted small">{{ $s->direction === 'airport_pickup' ? 'Airport pickup' : 'Airport drop-off' }}</div></td>
                <td class="nowrap">{{ $s->pickup_at->format('D j M, H:i') }}</td>
                <td class="nowrap">{{ $s->flight_number }} <x-status :value="$s->flight_status" /></td>
                <td>{{ $s->rider->name }}<div class="muted small">{{ $s->passengers }} pax · {{ $s->large_bags }} large bags</div></td>
                <td class="small">{{ Str::limit($s->address, 36) }}</td>
                <td>{{ $s->rideType->name }}</td>
                <td>{!! $s->driver ? e($s->driver->name) : '<span class="badge orange">Unassigned</span>' !!}</td>
                <td class="right">{{ naira($s->price) }}</td>
                <td><x-status :value="$s->status" /></td>
            </tr>
        @empty
            <tr><td colspan="9" class="empty">No shuttle bookings.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $shuttles->links() }}
</div>
@endsection
