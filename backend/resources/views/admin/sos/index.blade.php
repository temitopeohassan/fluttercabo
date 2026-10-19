@extends('admin.layout')
@section('title', 'SOS alerts')
@section('content')
<div class="page-head"><div><h1>SOS alerts</h1><p>Raised from the SOS button in either app. Call the person first; call 112 if they are in danger.</p></div></div>
<div class="stack">
@forelse ($alerts as $alert)
    <div class="card" @style(['border-color: var(--red); box-shadow: 0 0 0 2px var(--red-soft)' => $alert->status === 'open'])>
        <div class="card-head">
            <div class="row"><x-status :value="$alert->status" /><h2>{{ $alert->raisedBy?->name }} <span class="muted" style="font-weight:500">({{ $alert->raised_by_type }})</span></h2></div>
            <span class="muted">{{ $alert->created_at->format('D j M, H:i') }} · {{ $alert->created_at->diffForHumans() }}</span>
        </div>
        <div class="card-body grid grid-2">
            <dl class="dl">
                <dt>Phone</dt><dd><a href="tel:{{ $alert->raisedBy?->phone }}">{{ $alert->raisedBy?->phone }}</a></dd>
                <dt>Location</dt><dd>{{ $alert->address ?? 'Unknown' }}@if ($alert->lat)<div class="muted small"><a href="https://maps.google.com/?q={{ $alert->lat }},{{ $alert->lng }}" target="_blank" rel="noopener">{{ $alert->lat }}, {{ $alert->lng }}</a></div>@endif</dd>
                @if ($alert->trip)
                    <dt>Trip</dt><dd><a href="{{ route('admin.trips.show', $alert->trip) }}">{{ $alert->trip->reference }}</a></dd>
                    <dt>Rider</dt><dd>{{ $alert->trip->rider?->name }} · {{ $alert->trip->rider?->phone }}</dd>
                    <dt>Driver</dt><dd>{{ $alert->trip->driver?->name ?? '—' }} · {{ $alert->trip->driver?->phone }}</dd>
                @endif
                @if ($alert->handler)<dt>Handled by</dt><dd>{{ $alert->handler->name }}</dd>@endif
            </dl>
            <form method="post" action="{{ route('admin.sos.update', $alert) }}">
                @csrf @method('PUT')
                <div class="field"><label for="notes-{{ $alert->id }}">Notes</label><textarea id="notes-{{ $alert->id }}" name="notes" placeholder="What happened and what you did">{{ $alert->notes }}</textarea></div>
                @if ($alert->status !== 'resolved')
                    <div class="row">
                        @if ($alert->status === 'open')<button class="btn btn-yellow" name="status" value="acknowledged">Acknowledge</button>@endif
                        <button class="btn btn-primary" name="status" value="resolved">Resolve</button>
                    </div>
                @else
                    <p class="muted small">Resolved {{ $alert->resolved_at?->format('j M, H:i') }}.</p>
                @endif
            </form>
        </div>
    </div>
@empty
    <div class="card"><div class="empty">No SOS alerts.</div></div>
@endforelse
</div>
<div style="margin-top:16px">{{ $alerts->links() }}</div>
@endsection
