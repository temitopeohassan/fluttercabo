@extends('admin.layout')
@section('title', $code->exists ? $code->code : 'New promo code')
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.promo-codes.index') }}">Promo codes</a> / {{ $code->exists ? $code->code : 'New' }}</div>
<div class="page-head"><h1>{{ $code->exists ? $code->code : 'New promo code' }}</h1></div>
<form class="card" method="post" action="{{ $code->exists ? route('admin.promo-codes.update', $code) : route('admin.promo-codes.store') }}" style="max-width:760px">
    @csrf @if ($code->exists) @method('PUT') @endif
    <div class="card-body form-grid">
        <div class="field"><label for="code">Code</label><input id="code" type="text" name="code" value="{{ old('code', $code->code) }}" style="text-transform:uppercase" required></div>
        <div class="field"><label for="applies_to">Applies to</label><select id="applies_to" name="applies_to">@foreach (['all' => 'Everything', 'ride' => 'Rides', 'shuttle' => 'Airport shuttles', 'tour' => 'Tours'] as $v => $l)<option value="{{ $v }}" @selected(old('applies_to', $code->applies_to) === $v)>{{ $l }}</option>@endforeach</select></div>
        <div class="field full"><label for="description">Description shown to riders</label><input id="description" type="text" name="description" value="{{ old('description', $code->description) }}" required></div>
        <div class="field"><label for="discount_type">Discount type</label><select id="discount_type" name="discount_type"><option value="percent" @selected(old('discount_type', $code->discount_type) === 'percent')>Percent</option><option value="fixed" @selected(old('discount_type', $code->discount_type) === 'fixed')>Fixed naira</option></select></div>
        <div class="field"><label for="value">Value</label><input id="value" type="number" name="value" min="1" value="{{ old('value', $code->value) }}" required></div>
        <div class="field"><label for="max_discount">Cap (₦, percent codes)</label><input id="max_discount" type="number" name="max_discount" min="1" value="{{ old('max_discount', $code->max_discount) }}"></div>
        <div class="field"><label for="usage_limit">Total uses allowed</label><input id="usage_limit" type="number" name="usage_limit" min="1" value="{{ old('usage_limit', $code->usage_limit) }}" placeholder="Unlimited"></div>
        <div class="field"><label for="starts_at">Starts</label><input id="starts_at" type="date" name="starts_at" value="{{ old('starts_at', $code->starts_at?->toDateString()) }}"></div>
        <div class="field"><label for="ends_at">Ends</label><input id="ends_at" type="date" name="ends_at" value="{{ old('ends_at', $code->ends_at?->toDateString()) }}"></div>
        <div class="field"><label class="check"><input type="checkbox" name="first_booking_only" value="1" @checked(old('first_booking_only', $code->first_booking_only))> First booking only</label></div>
        <div class="field"><label class="check"><input type="checkbox" name="is_active" value="1" @checked(old('is_active', $code->is_active))> Active</label></div>
        <div class="full"><button class="btn btn-primary">Save code</button></div>
    </div>
</form>
@endsection
