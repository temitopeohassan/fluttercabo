@extends('admin.layout')
@section('title', 'Dashboard')
@section('content')
<div class="page-head">
    <div>
        <h1>Good {{ now()->hour < 12 ? 'morning' : (now()->hour < 17 ? 'afternoon' : 'evening') }}, {{ auth()->user()->name }}</h1>
        <p>{{ now()->format('l j F Y') }} · Lagos pilot: Victoria Island, Ikoyi, Lekki, Yaba and Surulere</p>
    </div>
</div>

<div class="grid grid-4">
    <div class="card kpi accent"><div class="label">Fares, last 30 days</div><div class="value">{{ naira($stats['gmv_30']) }}</div><div class="hint">{{ naira($stats['commission_30']) }} commission</div></div>
    <div class="card kpi"><div class="label">Trips today</div><div class="value">{{ $stats['trips_today'] }}</div><div class="hint">{{ $stats['active_trips'] }} in progress now</div></div>
    <div class="card kpi"><div class="label">Drivers online</div><div class="value">{{ $stats['drivers_online'] }}</div><div class="hint">of {{ $stats['drivers_approved'] }} approved</div></div>
    <div class="card kpi"><div class="label">Riders</div><div class="value">{{ number_format($stats['riders']) }}</div><div class="hint">{{ $stats['new_riders_7'] }} new this week · {{ $stats['waitlist'] }} on waitlist</div></div>
</div>

<div class="grid grid-main" style="margin-top:16px">
    <div class="card">
        <div class="card-head"><h2>Completed trips, last 14 days</h2><span class="muted small">Tours: {{ naira($stats['tour_revenue_30']) }} booked in 30 days</span></div>
        <div class="card-body">
            @php $max = max(1, $chart->max('trips')); @endphp
            <div class="bars" role="img" aria-label="Bar chart of completed trips per day">
                @foreach ($chart as $day)
                    <div class="bar" title="{{ \Illuminate\Support\Carbon::parse($day['date'])->format('D j M') }}: {{ $day['trips'] }} trips, {{ naira($day['gmv']) }}">
                        <small>{{ $day['trips'] }}</small>
                        <span style="height: {{ round($day['trips'] / $max * 100) }}%"></span>
                        <small>{{ \Illuminate\Support\Carbon::parse($day['date'])->format('j/n') }}</small>
                    </div>
                @endforeach
            </div>
        </div>
    </div>
    <div class="card">
        <div class="card-head"><h2>Needs attention</h2></div>
        <div>
            @foreach ([
                ['Open SOS alerts', $queues['sos'], route('admin.sos.index'), 'danger'],
                ['Driver applications to review', $queues['applications'], route('admin.drivers.index', ['status' => 'pending_review']), 'on'],
                ['Documents to review', $queues['documents'], route('admin.documents.index'), 'on'],
                ['Documents expiring in 30 days', $queues['expiring_documents'], route('admin.documents.index', ['status' => 'expiring']), 'on'],
                ['Airport shuttles without a driver', $queues['shuttles_unassigned'], route('admin.shuttles.index', ['status' => 'confirmed']), 'on'],
                ['Open support tickets', $queues['tickets'], route('admin.support.index'), 'on'],
                ['Payouts to process', $queues['payouts'], route('admin.payouts.index', ['status' => 'pending']), 'on'],
            ] as [$label, $count, $url, $tone])
                <a class="queue" href="{{ $url }}"><span @class(['dot', $tone => $count > 0])></span>{{ $label }}<span class="num">{{ $count }}</span></a>
            @endforeach
        </div>
    </div>
</div>

@if ($openSos->isNotEmpty())
<div class="card" style="margin-top:16px">
    <div class="card-head"><h2>Open SOS alerts</h2><a class="btn btn-danger btn-sm" href="{{ route('admin.sos.index') }}">Go to SOS</a></div>
    <div class="table-wrap"><table>
        <thead><tr><th>Raised</th><th>By</th><th>Location</th><th>Trip</th><th>Status</th></tr></thead>
        <tbody>
        @foreach ($openSos as $alert)
            <tr>
                <td class="nowrap">{{ $alert->created_at->diffForHumans() }}</td>
                <td>{{ $alert->raisedBy?->name }} <span class="muted small">({{ $alert->raised_by_type }})</span></td>
                <td>{{ $alert->address ?? ($alert->lat ? "$alert->lat, $alert->lng" : 'Unknown') }}</td>
                <td>@if ($alert->trip)<a href="{{ route('admin.trips.show', $alert->trip) }}">{{ $alert->trip->reference }}</a>@else <span class="muted">None</span> @endif</td>
                <td><x-status :value="$alert->status" /></td>
            </tr>
        @endforeach
        </tbody>
    </table></div>
</div>
@endif

<div class="grid grid-main" style="margin-top:16px">
    <div class="card">
        <div class="card-head"><h2>Latest trips</h2><a href="{{ route('admin.trips.index') }}">All trips</a></div>
        <div class="table-wrap"><table>
            <thead><tr><th>Trip</th><th>Rider</th><th>Driver</th><th>Type</th><th class="right">Fare</th><th>Status</th></tr></thead>
            <tbody>
            @foreach ($recentTrips as $trip)
                <tr>
                    <td><a class="strong mono" href="{{ route('admin.trips.show', $trip) }}">{{ $trip->reference }}</a><div class="muted small">{{ $trip->created_at->diffForHumans() }}</div></td>
                    <td>{{ $trip->rider?->name }}</td>
                    <td>{{ $trip->driver?->name ?? '—' }}</td>
                    <td>{{ $trip->rideType->name }}</td>
                    <td class="right nowrap">{{ naira($trip->fare_total) }}</td>
                    <td><x-status :value="$trip->status" /></td>
                </tr>
            @endforeach
            </tbody>
        </table></div>
    </div>
    <div class="card">
        <div class="card-head"><h2>Upcoming airport shuttles</h2><a href="{{ route('admin.shuttles.index') }}">All</a></div>
        <div>
            @forelse ($upcomingShuttles as $s)
                <a class="queue" href="{{ route('admin.shuttles.show', $s) }}">
                    <div>
                        <div class="strong">{{ $s->flight_number }} · {{ $s->direction === 'airport_pickup' ? 'Pickup' : 'Drop-off' }}</div>
                        <div class="muted small">{{ $s->pickup_at->format('D j M, H:i') }} · {{ $s->rider->name }}</div>
                    </div>
                    <span class="num">@if ($s->driver)<x-status value="driver_assigned" />@else<span class="badge orange">No driver</span>@endif</span>
                </a>
            @empty
                <div class="empty">No upcoming shuttles.</div>
            @endforelse
        </div>
    </div>
</div>
@endsection
