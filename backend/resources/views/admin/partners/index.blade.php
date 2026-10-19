@extends('admin.layout')
@section('title', 'Partners')
@section('content')
<div class="page-head">
    <div><h1>Partners</h1><p>Tour operators, guides, attractions and hotels. Check the CAC number before approving.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.partners.create') }}"><x-icon name="plus" width="16" height="16" /> Add partner</a>
</div>
<div class="card">
    <form class="filters" method="get">
        <select name="status" aria-label="Status"><option value="">Any status</option>@foreach (['pending', 'approved', 'suspended'] as $s)<option value="{{ $s }}" @selected(request('status') === $s)>{{ humanize($s) }}</option>@endforeach</select>
        <select name="type" aria-label="Type"><option value="">Any type</option>@foreach (['tour_operator', 'guide', 'attraction', 'hotel'] as $t)<option value="{{ $t }}" @selected(request('type') === $t)>{{ humanize($t) }}</option>@endforeach</select>
        <button class="btn btn-ghost" type="submit">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Partner</th><th>Type</th><th>Contact</th><th>CAC</th><th class="right">Commission</th><th class="right">Tours</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($partners as $p)
            <tr>
                <td><a class="strong" href="{{ route('admin.partners.edit', $p) }}">{{ $p->name }}</a></td>
                <td>{{ humanize($p->type) }}</td>
                <td>{{ $p->contact_name }}<div class="muted small">{{ $p->email }} · {{ $p->phone }}</div></td>
                <td class="mono">{{ $p->cac_number ?? '—' }}</td>
                <td class="right">{{ rtrim(rtrim(number_format($p->commission_rate, 2), '0'), '.') }}%</td>
                <td class="right">{{ $p->tours_count }}</td>
                <td><x-status :value="$p->status" /></td>
            </tr>
        @empty
            <tr><td colspan="7" class="empty">No partners.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $partners->links() }}
</div>
@endsection
