@extends('admin.layout')
@section('title', $admin->exists ? $admin->name : 'Add admin')
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.admins.index') }}">Admin users</a> / {{ $admin->exists ? $admin->name : 'Add admin' }}</div>
<div class="page-head"><h1>{{ $admin->exists ? $admin->name : 'Add admin' }}</h1></div>
<form class="card" method="post" action="{{ $admin->exists ? route('admin.admins.update', $admin) : route('admin.admins.store') }}" style="max-width:640px">
    @csrf @if ($admin->exists) @method('PUT') @endif
    <div class="card-body">
        <div class="field"><label for="name">Name</label><input id="name" type="text" name="name" value="{{ old('name', $admin->name) }}" required></div>
        <div class="field"><label for="email">Email</label><input id="email" type="email" name="email" value="{{ old('email', $admin->email) }}" required></div>
        <div class="field"><label for="role">Role</label><select id="role" name="role">@foreach (\App\Models\Admin::ROLES as $r)<option value="{{ $r }}" @selected(old('role', $admin->role) === $r)>{{ humanize($r) }}</option>@endforeach</select></div>
        <div class="field"><label for="password">{{ $admin->exists ? 'New password' : 'Password' }}</label><input id="password" type="password" name="password" autocomplete="new-password" @required(! $admin->exists)>@if ($admin->exists)<div class="hint">Leave empty to keep the current password.</div>@endif</div>
        @if ($admin->exists)
            <div class="field"><label class="check"><input type="checkbox" name="is_active" value="1" @checked(old('is_active', $admin->is_active))> Active (can sign in)</label></div>
        @endif
        <button class="btn btn-primary">Save</button>
    </div>
</form>
@endsection
