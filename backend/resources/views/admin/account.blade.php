@extends('admin.layout')
@section('title', 'Your account')
@section('content')
<div class="page-head"><div><h1>Your account</h1><p>{{ auth()->user()->email }} · {{ humanize(auth()->user()->role) }}</p></div></div>
<form class="card" method="post" action="{{ route('admin.account') }}" style="max-width:520px">
    @csrf @method('PUT')
    <div class="card-head"><h2>Change password</h2></div>
    <div class="card-body">
        <div class="field"><label for="current_password">Current password</label><input id="current_password" type="password" name="current_password" autocomplete="current-password" required></div>
        <div class="field"><label for="password">New password</label><input id="password" type="password" name="password" autocomplete="new-password" required><div class="hint">At least 8 characters.</div></div>
        <div class="field"><label for="password_confirmation">Confirm new password</label><input id="password_confirmation" type="password" name="password_confirmation" autocomplete="new-password" required></div>
        <button class="btn btn-primary">Change password</button>
    </div>
</form>
@endsection
