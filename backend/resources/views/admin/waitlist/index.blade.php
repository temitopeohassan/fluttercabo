@extends('admin.layout')
@section('title', 'Waitlist')
@section('content')
<div class="page-head">
    <div><h1>Waitlist</h1><p>{{ number_format($total) }} sign-ups from the caboapp.online form · {{ $invited }} invited</p></div>
    <a class="btn btn-ghost" href="{{ route('admin.waitlist.export') }}"><x-icon name="download" width="16" height="16" /> Export CSV</a>
</div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Name or email" aria-label="Search waitlist">
        <select name="source" aria-label="Source"><option value="">Any source</option>@foreach ($sources as $s)<option value="{{ $s }}" @selected(request('source') === $s)>{{ humanize($s) }}</option>@endforeach</select>
        <button class="btn btn-ghost">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Name</th><th>Email</th><th>Source</th><th>Signed up</th><th>Invited</th><th></th></tr></thead>
        <tbody>
        @forelse ($signups as $s)
            <tr>
                <td class="strong">{{ $s->name }}</td>
                <td><a href="mailto:{{ $s->email }}">{{ $s->email }}</a></td>
                <td>{{ humanize($s->source) }}</td>
                <td class="nowrap">{{ $s->created_at->format('j M Y') }}</td>
                <td>{{ $s->invited_at?->format('j M Y') ?? '—' }}</td>
                <td class="right nowrap">
                    @unless ($s->invited_at)
                        <form class="inline-form" method="post" action="{{ route('admin.waitlist.invite', $s) }}">@csrf<button class="btn btn-ghost btn-sm">Mark invited</button></form>
                    @endunless
                    <form class="inline-form" method="post" action="{{ route('admin.waitlist.destroy', $s) }}" onsubmit="return confirm('Remove this sign-up?')">@csrf @method('DELETE')<button class="btn btn-danger btn-sm">Remove</button></form>
                </td>
            </tr>
        @empty
            <tr><td colspan="6" class="empty">No sign-ups yet.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $signups->links() }}
</div>
@endsection
