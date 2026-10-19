@extends('admin.layout')
@section('title', 'Support')
@section('content')
<div class="page-head"><div><h1>Support</h1><p>Help centre tickets from riders and drivers. Urgent and high priority first.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <nav class="tabs" aria-label="Ticket status">
            @foreach (['active' => 'Active', 'open' => 'Open', 'in_review' => 'In review', 'awaiting_user' => 'Awaiting user', 'resolved' => 'Resolved', 'all' => 'All'] as $v => $l)
                <a href="{{ route('admin.support.index', ['status' => $v] + request()->only('category', 'mine')) }}" @class(['active' => $status === $v])>{{ $l }}</a>
            @endforeach
        </nav>
        <input type="hidden" name="status" value="{{ $status }}">
        <select name="category" aria-label="Category" onchange="this.form.submit()"><option value="">Any category</option>@foreach (\App\Models\SupportTicket::CATEGORIES as $c)<option value="{{ $c }}" @selected(request('category') === $c)>{{ humanize($c) }}</option>@endforeach</select>
        <label class="check"><input type="checkbox" name="mine" value="1" @checked(request()->boolean('mine')) onchange="this.form.submit()"> Assigned to me</label>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Ticket</th><th>From</th><th>Category</th><th>Priority</th><th>Assigned</th><th class="right">Messages</th><th>Updated</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($tickets as $t)
            <tr>
                <td><a class="strong" href="{{ route('admin.support.show', $t) }}">{{ $t->subject_line }}</a><div class="muted small mono">{{ $t->reference }}</div></td>
                <td>{{ $t->requester?->name }}<div class="muted small">{{ humanize($t->requester_type) }}</div></td>
                <td>{{ humanize($t->category) }}</td>
                <td><x-status :value="$t->priority" /></td>
                <td>{{ $t->assignee?->name ?? '—' }}</td>
                <td class="right">{{ $t->messages_count }}</td>
                <td class="nowrap muted">{{ $t->updated_at->diffForHumans() }}</td>
                <td><x-status :value="$t->status" /></td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No tickets here.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $tickets->links() }}
</div>
@endsection
