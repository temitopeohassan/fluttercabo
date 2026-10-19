@extends('admin.layout')
@section('title', $partner->exists ? $partner->name : 'Add partner')
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.partners.index') }}">Partners</a> / {{ $partner->exists ? $partner->name : 'Add partner' }}</div>
<div class="page-head"><h1>{{ $partner->exists ? $partner->name : 'Add partner' }}</h1></div>
<div class="grid grid-main">
    <form class="card" method="post" action="{{ $partner->exists ? route('admin.partners.update', $partner) : route('admin.partners.store') }}">
        @csrf @if ($partner->exists) @method('PUT') @endif
        <div class="card-body form-grid">
            <div class="field full"><label for="name">Business name</label><input id="name" type="text" name="name" value="{{ old('name', $partner->name) }}" required></div>
            <div class="field"><label for="type">Type</label><select id="type" name="type">@foreach (['tour_operator', 'guide', 'attraction', 'hotel'] as $t)<option value="{{ $t }}" @selected(old('type', $partner->type) === $t)>{{ humanize($t) }}</option>@endforeach</select></div>
            <div class="field"><label for="status">Status</label><select id="status" name="status">@foreach (['pending', 'approved', 'suspended'] as $s)<option value="{{ $s }}" @selected(old('status', $partner->status ?? 'pending') === $s)>{{ humanize($s) }}</option>@endforeach</select><div class="hint">Suspending unpublishes the partner's tours.</div></div>
            <div class="field"><label for="contact_name">Contact name</label><input id="contact_name" type="text" name="contact_name" value="{{ old('contact_name', $partner->contact_name) }}"></div>
            <div class="field"><label for="cac_number">CAC number</label><input id="cac_number" type="text" name="cac_number" value="{{ old('cac_number', $partner->cac_number) }}"></div>
            <div class="field"><label for="email">Email</label><input id="email" type="email" name="email" value="{{ old('email', $partner->email) }}"></div>
            <div class="field"><label for="phone">Phone</label><input id="phone" type="text" name="phone" value="{{ old('phone', $partner->phone) }}"></div>
            <div class="field"><label for="commission_rate">Commission (%)</label><input id="commission_rate" type="number" step="0.5" name="commission_rate" value="{{ old('commission_rate', $partner->commission_rate) }}" required></div>
            <div class="field"><label for="bank_name">Bank</label><input id="bank_name" type="text" name="bank_name" value="{{ old('bank_name', $partner->bank_name) }}"></div>
            <div class="field"><label for="bank_account_number">Account number</label><input id="bank_account_number" type="text" inputmode="numeric" name="bank_account_number" value="{{ old('bank_account_number', $partner->bank_account_number) }}"></div>
            <div class="field"><label for="bank_account_name">Account name</label><input id="bank_account_name" type="text" name="bank_account_name" value="{{ old('bank_account_name', $partner->bank_account_name) }}"></div>
            <div class="full"><button class="btn btn-primary">Save partner</button></div>
        </div>
    </form>
    @if ($partner->exists)
    <div class="card">
        <div class="card-head"><h2>Tours</h2></div>
        @forelse ($partner->tours as $t)
            <a class="queue" href="{{ route('admin.tours.show', $t) }}"><div class="strong">{{ $t->title }}</div><span class="num">{!! $t->is_published ? '<span class="badge green">Published</span>' : '<span class="badge">Draft</span>' !!}</span></a>
        @empty
            <div class="empty">No tours yet.</div>
        @endforelse
    </div>
    @endif
</div>
@endsection
