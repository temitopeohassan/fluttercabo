@extends('admin.layout')
@section('title', 'Payouts')
@section('content')
<div class="page-head">
    <div><h1>Driver payouts</h1><p>Weekly payouts every {{ \App\Models\Setting::read('weekly_payout_day', 'Tuesday') }}, plus instant cash-outs ({{ \App\Models\Setting::read('instant_cashout_fee_percent', 1.5) }}% fee). Cash commission owed is deducted first.</p></div>
    <form method="post" action="{{ route('admin.payouts.run-weekly') }}" onsubmit="return confirm('Create weekly payouts for {{ $weeklyDue['drivers'] }} drivers ({{ naira($weeklyDue['amount']) }})?')">
        @csrf
        <button class="btn btn-yellow">Run weekly payouts · {{ naira($weeklyDue['amount']) }}</button>
    </form>
</div>
<div class="card">
    <form class="filters" method="get">
        <select name="status" aria-label="Status"><option value="">Any status</option>@foreach (['pending', 'processing', 'paid', 'failed'] as $s)<option value="{{ $s }}" @selected(request('status') === $s)>{{ humanize($s) }}</option>@endforeach</select>
        <select name="type" aria-label="Type"><option value="">Weekly and instant</option><option value="weekly" @selected(request('type') === 'weekly')>Weekly</option><option value="instant" @selected(request('type') === 'instant')>Instant</option></select>
        <button class="btn btn-ghost">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Payout</th><th>Driver</th><th>Type</th><th>Bank</th><th class="right">Amount</th><th class="right">Fee</th><th>Status</th><th></th></tr></thead>
        <tbody>
        @forelse ($payouts as $p)
            <tr>
                <td class="mono strong">{{ $p->reference }}<div class="muted small" style="font-family:inherit">{{ $p->created_at->format('j M Y') }}{{ $p->period_start ? ' · week of '.$p->period_start->format('j M') : '' }}</div></td>
                <td><a href="{{ route('admin.drivers.show', $p->driver) }}">{{ $p->driver->name }}</a></td>
                <td>{{ humanize($p->type) }}</td>
                <td>{{ $p->bank_name }}<div class="muted small mono">{{ $p->bank_account_number }}</div></td>
                <td class="right nowrap strong">{{ naira($p->amount) }}</td>
                <td class="right">{{ $p->fee ? naira($p->fee) : '—' }}</td>
                <td><x-status :value="$p->status" />@if ($p->paid_at)<div class="muted small">{{ $p->paid_at->format('j M, H:i') }}</div>@endif</td>
                <td class="nowrap">
                    @if (in_array($p->status, ['pending', 'processing']))
                    <form method="post" action="{{ route('admin.payouts.update', $p) }}" class="row" style="gap:6px">
                        @csrf @method('PUT')
                        @if ($p->status === 'pending')<button class="btn btn-ghost btn-sm" name="status" value="processing">Processing</button>@endif
                        <button class="btn btn-primary btn-sm" name="status" value="paid">Mark paid</button>
                        <button class="btn btn-danger btn-sm" name="status" value="failed" onclick="return confirm('Mark as failed? The amount goes back to the driver balance.')">Failed</button>
                    </form>
                    @endif
                </td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No payouts.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $payouts->links() }}
</div>
@endsection
