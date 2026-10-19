@extends('admin.layout')
@section('title', 'Attractions')
@section('content')
<div class="page-head">
    <div><h1>Attractions</h1><p>The places guide in the rider app. Review each entry at least every quarter.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.attractions.create') }}"><x-icon name="plus" width="16" height="16" /> Add attraction</a>
</div>
<div class="card">
    <form class="filters" method="get"><input type="search" name="q" value="{{ request('q') }}" placeholder="Attraction name" aria-label="Search attractions"><button class="btn btn-ghost">Search</button></form>
    <div class="table-wrap"><table>
        <thead><tr><th></th><th>Attraction</th><th>Category</th><th>Hours</th><th class="right">Entry</th><th>Rating</th><th>Last reviewed</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($attractions as $a)
            <tr>
                <td style="width:80px">@if ($a->image)<img class="thumb" src="{{ $a->image }}" alt="">@else<div class="thumb"></div>@endif</td>
                <td><a class="strong" href="{{ route('admin.attractions.edit', $a) }}">{{ $a->name }}</a><div class="muted small">{{ $a->area }}</div></td>
                <td>{{ $a->category }}</td>
                <td>{{ $a->opening_hours }}</td>
                <td class="right">{{ $a->entry_fee ? naira($a->entry_fee) : 'Free' }}</td>
                <td>{{ $a->rating ? number_format($a->rating, 1).' ★' : '—' }}</td>
                <td @style(['color:#B45F0F;font-weight:600' => ! $a->last_reviewed_on || $a->last_reviewed_on->lt(now()->subMonths(3))])>{{ $a->last_reviewed_on?->format('j M Y') ?? 'Never' }}</td>
                <td>{!! $a->is_published ? '<span class="badge green">Published</span>' : '<span class="badge">Hidden</span>' !!}</td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No attractions.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $attractions->links() }}
</div>
@endsection
