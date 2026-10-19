@extends('admin.layout')
@section('title', 'Transactions')
@section('content')
<div class="page-head"><div><h1>Transactions</h1><p>Every charge, refund, top-up, tip, earning and payout.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Reference or description" aria-label="Search transactions">
        <select name="type" aria-label="Type"><option value="">Any type</option>@foreach (['charge', 'refund', 'wallet_topup', 'wallet_payment', 'tip', 'driver_earning', 'commission', 'payout', 'cash_settlement', 'referral_credit'] as $t)<option value="{{ $t }}" @selected(request('type') === $t)>{{ humanize($t) }}</option>@endforeach</select>
        <select name="method" aria-label="Method"><option value="">Any method</option>@foreach (['card', 'wallet', 'bank_transfer', 'cash', 'system'] as $m)<option value="{{ $m }}" @selected(request('method') === $m)>{{ humanize($m) }}</option>@endforeach</select>
        <button class="btn btn-ghost">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Reference</th><th>Who</th><th>Description</th><th>Type</th><th>Method</th><th class="right">Amount</th><th>Date</th></tr></thead>
        <tbody>
        @forelse ($transactions as $tx)
            <tr>
                <td class="mono">{{ $tx->reference }}</td>
                <td>
                    @if ($tx->owner)
                        <a href="{{ $tx->owner_type === 'rider' ? route('admin.riders.show', $tx->owner_id) : route('admin.drivers.show', $tx->owner_id) }}">{{ $tx->owner->name }}</a>
                        <div class="muted small">{{ humanize($tx->owner_type) }}</div>
                    @endif
                </td>
                <td>{{ $tx->description }}</td>
                <td>{{ humanize($tx->type) }}</td>
                <td>{{ humanize($tx->method) }}</td>
                <td class="right nowrap" style="color: {{ $tx->direction === 'credit' ? 'var(--green)' : 'inherit' }}">{{ $tx->direction === 'credit' ? '+' : '−' }}{{ naira($tx->amount) }}</td>
                <td class="nowrap muted">{{ $tx->created_at->format('j M Y, H:i') }}</td>
            </tr>
        @empty
            <tr><td colspan="7" class="empty">No transactions.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $transactions->links() }}
</div>
@endsection
