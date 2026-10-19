@extends('admin.layout')
@section('title', 'Settings')
@section('content')
<div class="page-head"><div><h1>Settings</h1><p>Platform rules used by the apps and the fare engine. Changes apply straight away.</p></div></div>
<form method="post" action="{{ route('admin.settings') }}">
    @csrf @method('PUT')
    <div class="grid grid-2">
        @foreach ($groups as $group => $settings)
            <div class="card">
                <div class="card-head"><h2>{{ humanize($group) }}</h2></div>
                <div class="card-body">
                    @foreach ($settings as $setting)
                        <div class="field">
                            <label for="s-{{ $setting->key }}">{{ $setting->label }}</label>
                            <input id="s-{{ $setting->key }}" type="text" name="settings[{{ $setting->key }}]" value="{{ old('settings.'.$setting->key, $setting->value) }}">
                        </div>
                    @endforeach
                </div>
            </div>
        @endforeach
    </div>
    <div style="margin-top:16px"><button class="btn btn-primary">Save settings</button></div>
</form>
@endsection
