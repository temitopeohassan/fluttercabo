@extends('admin.layout')
@section('title', 'Promo codes')
@section('content')
<div class="page-head">
    <div><h1>Promo codes</h1><p>Discounts riders can enter at checkout.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.promo-codes.create') }}"><x-icon name="plus" width="16" height="16" /> New code</a>
</div>
<div class="card"><div class="table-wrap"><table>
    <thead><tr><th>Code</th><th>Discount</th><th>Applies to</th><th>Used</th><th>Valid</th><th>Status</th></tr></thead>
    <tbody>
    @forelse ($codes as $c)
        <tr>
            <td><a class="strong mono" href="{{ route('admin.promo-codes.edit', $c) }}">{{ $c->code }}</a><div class="muted small">{{ $c->description }}</div></td>
            <td>{{ $c->discount_type === 'percent' ? $c->value.'%' : naira($c->value) }}@if ($c->max_discount)<div class="muted small">up to {{ naira($c->max_discount) }}</div>@endif</td>
            <td>{{ humanize($c->applies_to) }}{{ $c->first_booking_only ? ' · first booking' : '' }}</td>
            <td>{{ $c->used_count }}{{ $c->usage_limit ? ' / '.$c->usage_limit : '' }}</td>
            <td class="small nowrap">{{ $c->starts_at?->format('j M Y') ?? 'Now' }} → {{ $c->ends_at?->format('j M Y') ?? 'No end' }}</td>
            <td>@if (! $c->is_active)<span class="badge">Off</span>@elseif ($c->ends_at?->isPast())<x-status value="expired" />@else<x-status value="active" />@endif</td>
        </tr>
    @empty
        <tr><td colspan="6" class="empty">No promo codes.</td></tr>
    @endforelse
    </tbody>
</table></div>{{ $codes->links() }}</div>
@endsection
