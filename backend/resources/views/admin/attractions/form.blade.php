@extends('admin.layout')
@section('title', $attraction->exists ? $attraction->name : 'Add attraction')
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.attractions.index') }}">Attractions</a> / {{ $attraction->exists ? $attraction->name : 'Add attraction' }}</div>
<div class="page-head"><h1>{{ $attraction->exists ? $attraction->name : 'Add attraction' }}</h1></div>
<form method="post" action="{{ $attraction->exists ? route('admin.attractions.update', $attraction) : route('admin.attractions.store') }}">
    @csrf @if ($attraction->exists) @method('PUT') @endif
    <div class="grid grid-main">
        <div class="card"><div class="card-body form-grid">
            <div class="field full"><label for="name">Name</label><input id="name" type="text" name="name" value="{{ old('name', $attraction->name) }}" required></div>
            <div class="field"><label for="category">Category</label><input id="category" type="text" name="category" value="{{ old('category', $attraction->category) }}" placeholder="Nature, Art, Beaches, History…" required></div>
            <div class="field"><label for="area">Area</label><input id="area" type="text" name="area" value="{{ old('area', $attraction->area) }}" required></div>
            <div class="field full"><label for="description">Description</label><textarea id="description" name="description" required>{{ old('description', $attraction->description) }}</textarea></div>
            <div class="field full"><label for="address">Address</label><input id="address" type="text" name="address" value="{{ old('address', $attraction->address) }}"></div>
            <div class="field"><label for="lat">Latitude</label><input id="lat" type="text" inputmode="decimal" name="lat" value="{{ old('lat', $attraction->lat) }}" required></div>
            <div class="field"><label for="lng">Longitude</label><input id="lng" type="text" inputmode="decimal" name="lng" value="{{ old('lng', $attraction->lng) }}" required></div>
            <div class="field full"><label for="visitor_tips">Visitor tips</label><textarea id="visitor_tips" name="visitor_tips">{{ old('visitor_tips', implode("\n", $attraction->visitor_tips ?? [])) }}</textarea><div class="hint">One tip per line.</div></div>
            <div class="field full"><label for="safety_notes">Safety notes</label><textarea id="safety_notes" name="safety_notes">{{ old('safety_notes', $attraction->safety_notes) }}</textarea></div>
        </div></div>
        <div class="stack"><div class="card"><div class="card-body">
            <div class="field"><label for="opening_hours">Opening hours</label><input id="opening_hours" type="text" name="opening_hours" value="{{ old('opening_hours', $attraction->opening_hours) }}"></div>
            <div class="field"><label for="entry_fee">Entry fee (₦, 0 for free)</label><input id="entry_fee" type="number" name="entry_fee" min="0" value="{{ old('entry_fee', $attraction->entry_fee ?? 0) }}" required></div>
            <div class="field"><label for="image_url">Image</label><input id="image_url" type="text" name="image_url" value="{{ old('image_url', $attraction->image_url) }}"></div>
            <div class="field"><label for="slug">URL slug</label><input id="slug" type="text" name="slug" value="{{ old('slug', $attraction->slug) }}" placeholder="Made from the name if empty"></div>
            <div class="field"><label class="check"><input type="hidden" name="is_published" value="0"><input type="checkbox" name="is_published" value="1" @checked(old('is_published', $attraction->is_published))> Published</label></div>
            <p class="muted small">Saving marks the entry as reviewed today.</p>
            <button class="btn btn-primary btn-block">Save attraction</button>
        </div></div></div>
    </div>
</form>
@if ($attraction->exists)
<form method="post" action="{{ route('admin.attractions.destroy', $attraction) }}" onsubmit="return confirm('Delete this attraction?')" style="margin-top:16px">
    @csrf @method('DELETE')
    <button class="btn btn-danger">Delete attraction</button>
</form>
@endif
@endsection
