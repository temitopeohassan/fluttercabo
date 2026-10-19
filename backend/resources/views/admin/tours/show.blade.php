@extends('admin.layout')
@section('title', $tour->title)
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.tours.index') }}">Tours</a> / {{ $tour->title }}</div>
<div class="page-head">
    <div class="row"><h1>{{ $tour->title }}</h1>@if ($tour->is_published)<span class="badge green">Published</span>@else<span class="badge">Draft</span>@endif</div>
    <div class="row">
        <a class="btn btn-ghost" href="{{ route('admin.tour-bookings.index', ['tour' => $tour->id]) }}">Bookings</a>
        <a class="btn btn-primary" href="{{ route('admin.tours.edit', $tour) }}">Edit tour</a>
    </div>
</div>

<div class="grid grid-main">
    <div class="stack">
        <div class="card">
            <div class="card-head"><h2>Upcoming slots</h2><span class="muted small">{{ $slots->count() }} shown</span></div>
            <div class="table-wrap"><table>
                <thead><tr><th>Starts</th><th>Booked</th><th>Capacity and guide</th><th></th></tr></thead>
                <tbody>
                @forelse ($slots as $slot)
                    <tr>
                        <td class="nowrap strong">{{ $slot->starts_at->format('D j M, H:i') }}</td>
                        <td>{{ $slot->booked }} / {{ $slot->capacity }} @if ($slot->remaining === 0)<span class="badge red plain">Full</span>@endif</td>
                        <td>
                            <form class="row" style="gap:6px" method="post" action="{{ route('admin.slots.update', $slot) }}">
                                @csrf @method('PUT')
                                <input type="number" name="capacity" value="{{ $slot->capacity }}" min="{{ max(1, $slot->booked) }}" aria-label="Capacity" style="width:80px;min-height:32px;padding:4px 8px">
                                <select name="guide_driver_id" aria-label="Guide" style="width:auto;min-height:32px;padding:4px 8px">
                                    <option value="">No Cabo guide</option>
                                    @foreach ($guides as $g)<option value="{{ $g->id }}" @selected($slot->guide_driver_id === $g->id)>{{ $g->name }}</option>@endforeach
                                </select>
                                <button class="btn btn-ghost btn-sm">Save</button>
                            </form>
                        </td>
                        <td class="right">
                            @if ($slot->booked === 0)
                            <form method="post" action="{{ route('admin.slots.destroy', $slot) }}">@csrf @method('DELETE')<button class="btn btn-danger btn-sm">Remove</button></form>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="empty">No upcoming slots. Add some below.</td></tr>
                @endforelse
                </tbody>
            </table></div>
        </div>

        <div class="card">
            <div class="card-head"><h2>Add slots</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.tours.slots.store', $tour) }}">
                @csrf
                <div class="form-grid">
                    <div class="field"><label for="from">From</label><input id="from" type="date" name="from" value="{{ today()->toDateString() }}" required></div>
                    <div class="field"><label for="to">To</label><input id="to" type="date" name="to" value="{{ today()->addDays(13)->toDateString() }}" required></div>
                    <div class="field"><label for="time">Start time</label><input id="time" type="time" name="time" value="09:00" required></div>
                    <div class="field"><label for="capacity">Capacity</label><input id="capacity" type="number" name="capacity" value="{{ $tour->max_group_size }}" min="1" required></div>
                    <div class="field full">
                        <label>Days</label>
                        <div class="row">@foreach (['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as $i => $day)<label class="check"><input type="checkbox" name="days[]" value="{{ $i }}" checked> {{ $day }}</label>@endforeach</div>
                    </div>
                    <div class="field full">
                        <label for="guide">Cabo guide (optional)</label>
                        <select id="guide" name="guide_driver_id"><option value="">None</option>@foreach ($guides as $g)<option value="{{ $g->id }}">{{ $g->name }}</option>@endforeach</select>
                    </div>
                </div>
                <button class="btn btn-primary">Add slots</button>
            </form>
        </div>

        <div class="card">
            <div class="card-head"><h2>Latest reviews</h2></div>
            <div class="card-body">
                @forelse ($reviews as $r)
                    <div style="margin-bottom:12px">
                        <div class="row"><span class="strong">{{ str_repeat('★', $r->rating) }}{{ str_repeat('☆', 5 - $r->rating) }}</span><span class="muted small">{{ $r->rider->name }} · {{ $r->created_at->format('j M Y') }}</span>@unless ($r->is_visible)<span class="badge">Hidden</span>@endunless</div>
                        <p>{{ $r->comment }}</p>
                    </div>
                @empty
                    <p class="muted">No reviews yet.</p>
                @endforelse
            </div>
        </div>
    </div>

    <div class="stack">
        <div class="card">
            @if ($tour->image)<img class="hero-img" src="{{ $tour->image }}" alt="{{ $tour->title }}" style="border-radius: var(--radius) var(--radius) 0 0">@endif
            <div class="card-body">
                <p>{{ $tour->description }}</p>
                <dl class="dl" style="margin-top:12px">
                    <dt>Partner</dt><dd><a href="{{ route('admin.partners.edit', $tour->partner) }}">{{ $tour->partner->name }}</a></dd>
                    <dt>Category</dt><dd>{{ $tour->category->name }}</dd>
                    <dt>Price</dt><dd>{{ naira($tour->price) }} per person</dd>
                    <dt>Group</dt><dd>{{ $tour->min_group_size }}–{{ $tour->max_group_size }} people</dd>
                    <dt>Duration</dt><dd>{{ $tour->duration_minutes }} minutes</dd>
                    <dt>Meet at</dt><dd>{{ $tour->meeting_point }}</dd>
                    <dt>Languages</dt><dd>{{ implode(', ', $tour->languages ?? []) }}</dd>
                    <dt>Wheelchair</dt><dd>{{ $tour->wheelchair_accessible ? 'Accessible' : 'Not accessible' }}</dd>
                </dl>
            </div>
        </div>
        <div class="card"><div class="card-head"><h2>Itinerary</h2></div><div class="card-body"><ol class="steps">@foreach ($tour->itinerary ?? [] as $step)<li>{{ $step }}</li>@endforeach</ol></div></div>
        <div class="card"><div class="card-head"><h2>Included, excluded and add-ons</h2></div><div class="card-body">
            <h3>Included</h3><ul class="pill-list" style="margin:6px 0 12px">@foreach ($tour->inclusions ?? [] as $i)<li>{{ $i }}</li>@endforeach</ul>
            <h3>Not included</h3><ul class="pill-list" style="margin:6px 0 12px">@foreach ($tour->exclusions ?? [] as $i)<li>{{ $i }}</li>@endforeach</ul>
            <h3>Add-ons</h3>
            @forelse ($tour->addons ?? [] as $a)<div>{{ $a['name'] }} · {{ naira($a['price']) }}</div>@empty<p class="muted">None.</p>@endforelse
            <p class="muted small" style="margin-top:12px">{{ $tour->cancellation_policy }}</p>
        </div></div>
    </div>
</div>
@endsection
