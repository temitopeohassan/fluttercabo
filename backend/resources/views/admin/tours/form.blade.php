@extends('admin.layout')
@section('title', $tour->exists ? 'Edit '.$tour->title : 'New tour')
@section('content')
@php $lines = fn ($v) => implode("\n", $v ?? []); @endphp
<div class="breadcrumb"><a href="{{ route('admin.tours.index') }}">Tours</a> / {{ $tour->exists ? $tour->title : 'New tour' }}</div>
<div class="page-head"><h1>{{ $tour->exists ? 'Edit tour' : 'New tour' }}</h1></div>
<form method="post" action="{{ $tour->exists ? route('admin.tours.update', $tour) : route('admin.tours.store') }}">
    @csrf @if ($tour->exists) @method('PUT') @endif
    <div class="grid grid-main">
        <div class="card"><div class="card-body form-grid">
            <div class="field full"><label for="title">Title</label><input id="title" type="text" name="title" value="{{ old('title', $tour->title) }}" required></div>
            <div class="field">
                <label for="partner_id">Partner</label>
                <select id="partner_id" name="partner_id" required>@foreach ($partners as $p)<option value="{{ $p->id }}" @selected(old('partner_id', $tour->partner_id) == $p->id)>{{ $p->name }}{{ $p->status !== 'approved' ? ' ('.$p->status.')' : '' }}</option>@endforeach</select>
            </div>
            <div class="field">
                <label for="tour_category_id">Category</label>
                <select id="tour_category_id" name="tour_category_id" required>@foreach ($categories as $c)<option value="{{ $c->id }}" @selected(old('tour_category_id', $tour->tour_category_id) == $c->id)>{{ $c->name }}</option>@endforeach</select>
            </div>
            <div class="field full"><label for="description">Description</label><textarea id="description" name="description" required>{{ old('description', $tour->description) }}</textarea></div>
            <div class="field"><label for="area">Area</label><input id="area" type="text" name="area" value="{{ old('area', $tour->area) }}" required></div>
            <div class="field"><label for="duration_minutes">Duration (minutes)</label><input id="duration_minutes" type="number" name="duration_minutes" value="{{ old('duration_minutes', $tour->duration_minutes) }}" min="30" required></div>
            <div class="field full"><label for="meeting_point">Meeting point</label><input id="meeting_point" type="text" name="meeting_point" value="{{ old('meeting_point', $tour->meeting_point) }}" required></div>
            <div class="field"><label for="meeting_lat">Meeting latitude</label><input id="meeting_lat" type="text" inputmode="decimal" name="meeting_lat" value="{{ old('meeting_lat', $tour->meeting_lat) }}"></div>
            <div class="field"><label for="meeting_lng">Meeting longitude</label><input id="meeting_lng" type="text" inputmode="decimal" name="meeting_lng" value="{{ old('meeting_lng', $tour->meeting_lng) }}"></div>
            <div class="field full"><label for="itinerary">Itinerary</label><textarea id="itinerary" name="itinerary">{{ old('itinerary', $lines($tour->itinerary)) }}</textarea><div class="hint">One step per line.</div></div>
            <div class="field"><label for="inclusions">Included</label><textarea id="inclusions" name="inclusions">{{ old('inclusions', $lines($tour->inclusions)) }}</textarea><div class="hint">One per line.</div></div>
            <div class="field"><label for="exclusions">Not included</label><textarea id="exclusions" name="exclusions">{{ old('exclusions', $lines($tour->exclusions)) }}</textarea><div class="hint">One per line.</div></div>
            <div class="field full"><label for="addons">Add-ons</label><textarea id="addons" name="addons">{{ old('addons', collect($tour->addons ?? [])->map(fn ($a) => $a['name'].' | '.$a['price'])->implode("\n")) }}</textarea><div class="hint">One per line as <span class="mono">Name | price in naira</span>, e.g. <span class="mono">Picnic lunch | 6000</span>.</div></div>
        </div></div>
        <div class="stack">
            <div class="card"><div class="card-body">
                <div class="field"><label for="price">Price per person (₦)</label><input id="price" type="number" name="price" value="{{ old('price', $tour->price) }}" min="0" required></div>
                <div class="form-grid">
                    <div class="field"><label for="min_group_size">Min group</label><input id="min_group_size" type="number" name="min_group_size" value="{{ old('min_group_size', $tour->min_group_size) }}" min="1" required></div>
                    <div class="field"><label for="max_group_size">Max group</label><input id="max_group_size" type="number" name="max_group_size" value="{{ old('max_group_size', $tour->max_group_size) }}" min="1" required></div>
                </div>
                <div class="field"><label for="languages">Languages</label><input id="languages" type="text" name="languages" value="{{ old('languages', implode(', ', $tour->languages ?? [])) }}"><div class="hint">Comma separated.</div></div>
                <div class="field"><label for="image_url">Image</label><input id="image_url" type="text" name="image_url" value="{{ old('image_url', $tour->image_url) }}" placeholder="/images/places/tarkwa-bay.jpg"><div class="hint">A full URL, or a path under <span class="mono">public/</span>.</div></div>
                <div class="field"><label for="cancellation_policy">Cancellation policy</label><input id="cancellation_policy" type="text" name="cancellation_policy" value="{{ old('cancellation_policy', $tour->cancellation_policy ?? 'Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.') }}"></div>
                <div class="field"><label for="slug">URL slug</label><input id="slug" type="text" name="slug" value="{{ old('slug', $tour->slug) }}" placeholder="Made from the title if empty"></div>
                <div class="field"><label class="check"><input type="hidden" name="wheelchair_accessible" value="0"><input type="checkbox" name="wheelchair_accessible" value="1" @checked(old('wheelchair_accessible', $tour->wheelchair_accessible))> Wheelchair accessible</label></div>
                <div class="field"><label class="check"><input type="hidden" name="is_featured" value="0"><input type="checkbox" name="is_featured" value="1" @checked(old('is_featured', $tour->is_featured))> Featured on Explore</label></div>
                <div class="field"><label class="check"><input type="hidden" name="is_published" value="0"><input type="checkbox" name="is_published" value="1" @checked(old('is_published', $tour->is_published))> Published</label></div>
                <button class="btn btn-primary btn-block">Save tour</button>
            </div></div>
        </div>
    </div>
</form>
@if ($tour->exists)
<form method="post" action="{{ route('admin.tours.destroy', $tour) }}" onsubmit="return confirm('Delete this tour? Tours with bookings are unpublished instead.')" style="margin-top:16px">
    @csrf @method('DELETE')
    <button class="btn btn-danger">Delete tour</button>
</form>
@endif
@endsection
