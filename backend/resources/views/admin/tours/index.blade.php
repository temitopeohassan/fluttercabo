@extends('admin.layout')
@section('title', 'Tours')
@section('content')
<div class="page-head">
    <div><h1>Tours</h1><p>Experiences sold in the rider app's Explore tab.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.tours.create') }}"><x-icon name="plus" width="16" height="16" /> New tour</a>
</div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Tour name" aria-label="Search tours">
        <select name="category" aria-label="Category">
            <option value="">All categories</option>
            @foreach ($categories as $c)<option value="{{ $c->id }}" @selected(request('category') == $c->id)>{{ $c->name }}</option>@endforeach
        </select>
        <button class="btn btn-ghost" type="submit">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th></th><th>Tour</th><th>Partner</th><th>Category</th><th class="right">Price</th><th>Rating</th><th class="right">Bookings</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($tours as $tour)
            <tr>
                <td style="width:80px">@if ($tour->image)<img class="thumb" src="{{ $tour->image }}" alt="">@else<div class="thumb"></div>@endif</td>
                <td><a class="strong" href="{{ route('admin.tours.show', $tour) }}">{{ $tour->title }}</a><div class="muted small">{{ $tour->area }} · {{ intdiv($tour->duration_minutes, 60) }}h{{ $tour->duration_minutes % 60 ? ' '.($tour->duration_minutes % 60).'m' : '' }}</div></td>
                <td>{{ $tour->partner->name }}</td>
                <td>{{ $tour->category->name }}</td>
                <td class="right">{{ naira($tour->price) }}</td>
                <td>{{ $tour->rating ? number_format($tour->rating, 1).' ★' : '—' }} <span class="muted small">({{ number_format($tour->reviews_count) }})</span></td>
                <td class="right">{{ $tour->bookings_count }}</td>
                <td>@if ($tour->is_published)<span class="badge green">Published</span>@else<span class="badge">Draft</span>@endif @if ($tour->is_featured)<span class="badge yellow plain">Featured</span>@endif</td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No tours yet.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $tours->links() }}
</div>
@endsection
