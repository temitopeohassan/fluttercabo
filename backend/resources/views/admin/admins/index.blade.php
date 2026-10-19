@extends('admin.layout')
@section('title', 'Admin users')
@section('content')
<div class="page-head">
    <div><h1>Admin users</h1><p>Operations: drivers, trips, tours, zones. Support: tickets, SOS, refunds. Finance: pricing, promo codes, payouts, refunds. Super admin: everything.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.admins.create') }}"><x-icon name="plus" width="16" height="16" /> Add admin</a>
</div>
<div class="card"><div class="table-wrap"><table>
    <thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Last sign-in</th><th>Status</th></tr></thead>
    <tbody>
    @foreach ($admins as $a)
        <tr>
            <td><a class="strong" href="{{ route('admin.admins.edit', $a) }}">{{ $a->name }}</a>@if ($a->is(auth()->user()))<span class="badge plain">You</span>@endif</td>
            <td>{{ $a->email }}</td>
            <td>{{ humanize($a->role) }}</td>
            <td>{{ $a->last_login_at?->diffForHumans() ?? 'Never' }}</td>
            <td>{!! $a->is_active ? '<span class="badge green">Active</span>' : '<span class="badge red">Deactivated</span>' !!}</td>
        </tr>
    @endforeach
    </tbody>
</table></div></div>
@endsection
