@extends('admin.layout')
@section('title', $driver->name)
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.drivers.index') }}">Drivers</a> / {{ $driver->name }}</div>
<div class="page-head">
    <div class="row">
        <div class="avatar" style="width:52px;height:52px;font-size:18px">{{ strtoupper(substr($driver->first_name ?? 'D', 0, 1)) }}</div>
        <div>
            <h1>{{ $driver->name }}</h1>
            <p>{{ humanize($driver->driver_type) }} driver{{ $driver->fleetPartner ? ' with '.$driver->fleetPartner->name : '' }} · {{ humanize($driver->tier) }} tier{{ $driver->is_tour_guide ? ' · tour guide' : '' }}</p>
        </div>
        <x-status :value="$driver->status" />
        @if ($driver->is_online)<span class="badge green">Online</span>@endif
    </div>
</div>

@if ($driver->status_reason)
    <div class="flash err">{{ $driver->status_reason }}</div>
@endif

<div class="grid grid-main">
    <div class="stack">
        <div class="card">
            <div class="card-head"><h2>Account decision</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.drivers.status', $driver) }}">
                @csrf
                <div class="form-grid">
                    <div class="field">
                        <label for="status">Status</label>
                        <select id="status" name="status">
                            @foreach (['approved' => 'Approve', 'pending_review' => 'Back to review', 'suspended' => 'Suspend', 'rejected' => 'Reject'] as $value => $label)
                                <option value="{{ $value }}" @selected($driver->status === $value)>{{ $label }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="field">
                        <label for="tier">Tier</label>
                        <select id="tier" name="tier">
                            <option value="standard" @selected($driver->tier === 'standard')>Standard</option>
                            <option value="premium" @selected($driver->tier === 'premium')>Premium</option>
                        </select>
                    </div>
                    <div class="field full">
                        <label for="reason">Reason <span class="muted">(required to suspend or reject, shown to the driver)</span></label>
                        <input id="reason" type="text" name="reason" value="{{ old('reason') }}">
                    </div>
                </div>
                <button class="btn btn-primary">Save decision</button>
            </form>
            @if ($blockers)
                <div class="card-body" style="border-top:1px solid var(--line)">
                    <h3 style="margin-bottom:6px">Why this driver cannot go online</h3>
                    <ul style="margin:0;padding-left:18px">@foreach ($blockers as $b)<li>{{ $b }}</li>@endforeach</ul>
                </div>
            @endif
        </div>

        <div class="card">
            <div class="card-head"><h2>Documents</h2><span class="muted small">{{ $driver->documents->where('status', 'approved')->count() }} of {{ $driver->documents->count() }} approved</span></div>
            <div class="table-wrap"><table>
                <thead><tr><th>Document</th><th>Expires</th><th>Status</th><th>Review</th></tr></thead>
                <tbody>
                @forelse ($driver->documents->sortBy('type') as $doc)
                    <tr>
                        <td><a class="strong" href="{{ route('admin.documents.file', $doc) }}">{{ $doc->label }}</a>@if ($doc->rejection_reason)<div class="muted small">{{ $doc->rejection_reason }}</div>@endif</td>
                        <td class="nowrap">
                            @if ($doc->expires_at)
                                {{ $doc->expires_at->format('j M Y') }}
                                @if ($doc->isExpired())<x-status value="expired" />@elseif ($doc->expires_at->lte(now()->addDays(30)))<span class="badge orange">Soon</span>@endif
                            @else <span class="muted">—</span> @endif
                        </td>
                        <td><x-status :value="$doc->status" /><div class="muted small">{{ $doc->reviewer ? 'by '.$doc->reviewer->name : '' }}</div></td>
                        <td>@include('admin.drivers.review-form', ['doc' => $doc])</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="empty">No documents uploaded yet.</td></tr>
                @endforelse
                </tbody>
            </table></div>
        </div>

        <div class="card">
            <div class="card-head"><h2>Recent trips</h2><span class="muted small">{{ naira($earnings30) }} earned in 30 days</span></div>
            <div class="table-wrap"><table>
                <thead><tr><th>Trip</th><th>Rider</th><th>Type</th><th class="right">Fare</th><th class="right">Earned</th><th>Status</th></tr></thead>
                <tbody>
                @forelse ($trips as $trip)
                    <tr>
                        <td><a class="strong mono" href="{{ route('admin.trips.show', $trip) }}">{{ $trip->reference }}</a><div class="muted small">{{ $trip->created_at->format('j M, H:i') }}</div></td>
                        <td>{{ $trip->rider?->name }}</td>
                        <td>{{ $trip->rideType->name }} · {{ humanize($trip->payment_method) }}</td>
                        <td class="right">{{ naira($trip->fare_total) }}</td>
                        <td class="right">{{ naira($trip->driver_earnings) }}</td>
                        <td><x-status :value="$trip->status" /></td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="empty">No trips yet.</td></tr>
                @endforelse
                </tbody>
            </table></div>
        </div>
    </div>

    <div class="stack">
        <div class="card"><div class="card-body">
            <dl class="dl">
                <dt>Phone</dt><dd>{{ $driver->phone }}</dd>
                <dt>Email</dt><dd>{{ $driver->email ?? '—' }}</dd>
                <dt>Born</dt><dd>{{ $driver->date_of_birth?->format('j M Y') ?? '—' }}</dd>
                <dt>Address</dt><dd>{{ $driver->address ?? '—' }}</dd>
                <dt>Languages</dt><dd>{{ implode(', ', $driver->languages ?? []) ?: '—' }}</dd>
                <dt>Rating</dt><dd>{{ $driver->rating ? number_format($driver->rating, 2).' ★' : '—' }}</dd>
                <dt>Acceptance</dt><dd>{{ $driver->acceptance_rate }}%</dd>
                <dt>Cancellation</dt><dd>{{ $driver->cancellation_rate }}%</dd>
                <dt>Training</dt><dd>{{ $driver->training_completed ? 'Completed' : 'Not yet' }}</dd>
                <dt>Background</dt><dd>{{ $driver->background_check_consent ? 'Consent given' : 'No consent' }}</dd>
                <dt>Inspection</dt><dd>{{ $driver->inspection_at?->format('j M Y, H:i') ?? '—' }}<div class="muted small">{{ $driver->inspection_location }}</div></dd>
                <dt>Approved</dt><dd>{{ $driver->approved_at?->format('j M Y') ?? '—' }}</dd>
                <dt>Referral</dt><dd class="mono">{{ $driver->referral_code }}</dd>
            </dl>
        </div></div>

        <div class="card">
            <div class="card-head"><h2>Money</h2></div>
            <div class="card-body">
                <dl class="dl">
                    <dt>Earnings balance</dt><dd>{{ naira($driver->earnings_balance) }}</dd>
                    <dt>Cash commission owed</dt><dd>{{ naira($driver->cash_commission_owed) }}</dd>
                    <dt>Bank</dt><dd>{{ $driver->bank_name ?? '—' }} <span class="mono">{{ $driver->bank_account_number }}</span><div class="muted small">{{ $driver->bank_account_name }}</div></dd>
                </dl>
                @if ($driver->cash_commission_owed > 0)
                    <form method="post" action="{{ route('admin.drivers.settle-cash', $driver) }}" class="row" style="margin-top:14px">
                        @csrf
                        <input type="number" name="amount" min="1" max="{{ $driver->cash_commission_owed }}" value="{{ $driver->cash_commission_owed }}" aria-label="Amount received" style="width:140px">
                        <button class="btn btn-ghost btn-sm">Record cash received</button>
                    </form>
                @endif
            </div>
        </div>

        <div class="card">
            <div class="card-head"><h2>Vehicles</h2></div>
            <div class="card-body">
                @forelse ($driver->vehicles as $v)
                    <div style="margin-bottom:14px">
                        <div class="row"><span class="strong">{{ $v->description }}</span> <x-status :value="$v->status" /> @if ($v->is_active)<span class="badge green plain">In use</span>@endif</div>
                        <div class="muted small"><span class="mono">{{ $v->plate_number }}</span> · {{ $v->seats }} seats{{ $v->wheelchair_accessible ? ' · wheelchair accessible' : '' }}</div>
                        <form method="post" action="{{ route('admin.vehicles.review', $v) }}" style="margin-top:8px">
                            @csrf
                            <div class="row small">
                                @foreach (\App\Models\RideType::orderBy('sort_order')->get() as $type)
                                    <label class="check"><input type="checkbox" name="ride_types[]" value="{{ $type->code }}" @checked(in_array($type->code, $v->ride_types ?? []))> {{ $type->name }}</label>
                                @endforeach
                            </div>
                            <div class="row" style="margin-top:8px">
                                <button class="btn btn-ghost btn-sm" name="status" value="approved">Approve</button>
                                <button class="btn btn-danger btn-sm" name="status" value="rejected">Reject</button>
                            </div>
                        </form>
                    </div>
                @empty
                    <p class="muted">No vehicle added yet.</p>
                @endforelse
            </div>
        </div>

        <div class="card">
            <div class="card-head"><h2>Payouts</h2><a href="{{ route('admin.payouts.index') }}">All payouts</a></div>
            <div>
                @forelse ($payouts as $p)
                    <div class="queue"><div><div class="strong">{{ naira($p->amount) }} · {{ humanize($p->type) }}</div><div class="muted small">{{ $p->reference }} · {{ $p->created_at->format('j M Y') }}</div></div><span class="num"><x-status :value="$p->status" /></span></div>
                @empty
                    <div class="empty">No payouts yet.</div>
                @endforelse
            </div>
        </div>

        @if ($tickets->isNotEmpty())
        <div class="card">
            <div class="card-head"><h2>Support tickets</h2></div>
            @foreach ($tickets as $t)
                <a class="queue" href="{{ route('admin.support.show', $t) }}"><div><div class="strong">{{ $t->subject_line }}</div><div class="muted small">{{ $t->reference }}</div></div><span class="num"><x-status :value="$t->status" /></span></a>
            @endforeach
        </div>
        @endif
    </div>
</div>
@endsection
