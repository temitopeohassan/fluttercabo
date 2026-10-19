@extends('admin.layout')
@section('title', $rider->name)
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.riders.index') }}">Riders</a> / {{ $rider->name }}</div>
<div class="page-head">
    <div class="row">
        <div class="avatar" style="width:52px;height:52px;font-size:18px">{{ strtoupper(substr($rider->first_name ?? 'R', 0, 1)) }}</div>
        <div><h1>{{ $rider->name }}</h1><p>{{ humanize($rider->traveller_type) }} traveller · {{ $rider->nationality }} · joined {{ $rider->created_at->format('j M Y') }}</p></div>
        <x-status :value="$rider->status" />
    </div>
    <form method="post" action="{{ route('admin.riders.status', $rider) }}">
        @csrf
        @if ($rider->status === 'active')
            <input type="hidden" name="status" value="suspended">
            <button class="btn btn-danger" onclick="return confirm('Suspend this rider? They will be signed out of the app.')">Suspend rider</button>
        @else
            <input type="hidden" name="status" value="active">
            <button class="btn btn-primary">Reinstate rider</button>
        @endif
    </form>
</div>

<div class="grid grid-main">
    <div class="stack">
        <div class="card">
            <div class="card-head"><h2>Recent trips</h2></div>
            <div class="table-wrap"><table>
                <thead><tr><th>Trip</th><th>Route</th><th>Driver</th><th class="right">Fare</th><th>Status</th></tr></thead>
                <tbody>
                @forelse ($trips as $trip)
                    <tr>
                        <td><a class="strong mono" href="{{ route('admin.trips.show', $trip) }}">{{ $trip->reference }}</a><div class="muted small">{{ $trip->created_at->format('j M, H:i') }}</div></td>
                        <td>{{ Str::limit($trip->pickup_address, 30) }} → {{ Str::limit($trip->dropoff_address, 30) }}</td>
                        <td>{{ $trip->driver?->name ?? '—' }}</td>
                        <td class="right nowrap">{{ naira($trip->fare_total) }}</td>
                        <td><x-status :value="$trip->status" /></td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="empty">No trips yet.</td></tr>
                @endforelse
                </tbody>
            </table></div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Tours and shuttles</h2></div>
            <div class="table-wrap"><table>
                <thead><tr><th>Booking</th><th>What</th><th>When</th><th class="right">Total</th><th>Status</th></tr></thead>
                <tbody>
                @foreach ($tourBookings as $b)
                    <tr><td><a class="strong mono" href="{{ route('admin.tour-bookings.show', $b) }}">{{ $b->reference }}</a></td><td>{{ $b->tour->title }} · {{ $b->guests }} {{ Str::plural('guest', $b->guests) }}</td><td class="nowrap">{{ $b->slot->starts_at->format('j M, H:i') }}</td><td class="right">{{ naira($b->total) }}</td><td><x-status :value="$b->status" /></td></tr>
                @endforeach
                @foreach ($shuttles as $s)
                    <tr><td><a class="strong mono" href="{{ route('admin.shuttles.show', $s) }}">{{ $s->reference }}</a></td><td>Airport {{ $s->direction === 'airport_pickup' ? 'pickup' : 'drop-off' }} · {{ $s->flight_number }}</td><td class="nowrap">{{ $s->pickup_at->format('j M, H:i') }}</td><td class="right">{{ naira($s->price) }}</td><td><x-status :value="$s->status" /></td></tr>
                @endforeach
                @if ($tourBookings->isEmpty() && $shuttles->isEmpty())
                    <tr><td colspan="5" class="empty">No bookings yet.</td></tr>
                @endif
                </tbody>
            </table></div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Payments</h2></div>
            @include('admin.partials.transactions', ['transactions' => $transactions])
        </div>
    </div>

    <div class="stack">
        <div class="card"><div class="card-body">
            <dl class="dl">
                <dt>Email</dt><dd>{{ $rider->email ?? '—' }}</dd>
                <dt>Phone</dt><dd>{{ $rider->phone ?? '—' }}</dd>
                <dt>Currency</dt><dd>{{ $rider->home_currency }}</dd>
                <dt>Language</dt><dd>{{ strtoupper($rider->language) }}</dd>
                <dt>Rating</dt><dd>{{ $rider->rating ? number_format($rider->rating, 2).' ★' : '—' }}</dd>
                <dt>Wallet</dt><dd>{{ naira($rider->wallet_balance) }}</dd>
                <dt>Points</dt><dd>{{ number_format($rider->loyalty_points) }}</dd>
                <dt>Referral</dt><dd class="mono">{{ $rider->referral_code }}</dd>
                @if ($rider->referredBy)<dt>Referred by</dt><dd><a href="{{ route('admin.riders.show', $rider->referredBy) }}">{{ $rider->referredBy->name }}</a></dd>@endif
                <dt>Last active</dt><dd>{{ $rider->last_active_at?->diffForHumans() ?? '—' }}</dd>
                @if ($rider->accessibility)<dt>Accessibility</dt><dd>{{ $rider->accessibility['assistance'] ?? 'Wheelchair user' }}</dd>@endif
            </dl>
        </div></div>
        <div class="card">
            <div class="card-head"><h2>Wallet credit</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.riders.credit', $rider) }}">
                @csrf
                <div class="field"><label for="amount">Amount (₦)</label><input id="amount" type="number" name="amount" min="100" step="100" required></div>
                <div class="field"><label for="reason">Reason</label><input id="reason" type="text" name="reason" placeholder="e.g. Goodwill credit for late driver" required></div>
                <button class="btn btn-ghost">Add credit</button>
            </form>
        </div>
        <div class="card">
            <div class="card-head"><h2>Emergency contacts</h2></div>
            <div class="card-body">
                @forelse ($rider->emergencyContacts as $c)
                    <p><span class="strong">{{ $c->name }}</span> <span class="muted">({{ $c->relationship }})</span><br>{{ $c->phone }} @if ($c->share_trips_automatically)<span class="badge green plain">Auto-share trips</span>@endif</p>
                @empty
                    <p class="muted">None added.</p>
                @endforelse
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Saved places</h2></div>
            <div class="card-body">
                @forelse ($rider->savedPlaces as $p)
                    <p><span class="strong">{{ $p->label }}</span><br><span class="muted">{{ $p->address }}</span></p>
                @empty
                    <p class="muted">None saved.</p>
                @endforelse
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Support tickets</h2></div>
            <div>
                @forelse ($tickets as $t)
                    <a class="queue" href="{{ route('admin.support.show', $t) }}"><div><div class="strong">{{ $t->subject_line }}</div><div class="muted small">{{ $t->reference }} · {{ $t->created_at->diffForHumans() }}</div></div><span class="num"><x-status :value="$t->status" /></span></a>
                @empty
                    <div class="empty">No tickets.</div>
                @endforelse
            </div>
        </div>
    </div>
</div>
@endsection
