@extends('admin.layout')
@section('title', 'Drivers')
@section('content')
<div class="page-head"><div><h1>Drivers</h1><p>Applications, approved drivers and their vehicles.</p></div></div>
<div class="card">
    <form class="filters" method="get">
        <input type="search" name="q" value="{{ request('q') }}" placeholder="Name, phone or plate number" aria-label="Search drivers">
        <select name="status" aria-label="Status">
            <option value="">Any status</option>
            @foreach (['applicant', 'pending_review', 'approved', 'suspended', 'rejected'] as $s)<option value="{{ $s }}" @selected(request('status') === $s)>{{ humanize($s) }}</option>@endforeach
        </select>
        <label class="check"><input type="checkbox" name="online" value="1" @checked(request()->boolean('online'))> Online now</label>
        <button class="btn btn-ghost" type="submit">Filter</button>
    </form>
    <div class="table-wrap"><table>
        <thead><tr><th>Driver</th><th>Vehicle</th><th>Tier</th><th class="right">Trips</th><th>Rating</th><th class="right">Acceptance</th><th class="right">Cash owed</th><th>Status</th></tr></thead>
        <tbody>
        @forelse ($drivers as $driver)
            <tr>
                <td>
                    <a class="strong" href="{{ route('admin.drivers.show', $driver) }}">{{ $driver->name }}</a>
                    @if ($driver->is_online)<span class="badge green plain">Online</span>@endif
                    <div class="muted small">{{ $driver->phone }}</div>
                </td>
                <td>@if ($driver->activeVehicle){{ $driver->activeVehicle->description }}<div class="muted small mono">{{ $driver->activeVehicle->plate_number }}</div>@else<span class="muted">None yet</span>@endif</td>
                <td>{{ humanize($driver->tier) }}@if ($driver->is_tour_guide)<div class="muted small">Tour guide</div>@endif</td>
                <td class="right">{{ $driver->trips_count }}</td>
                <td>{{ $driver->rating ? number_format($driver->rating, 2).' ★' : '—' }}</td>
                <td class="right">{{ $driver->rating ? $driver->acceptance_rate.'%' : '—' }}</td>
                <td class="right nowrap" @style(['color: #B42318; font-weight:600' => $driver->cash_commission_owed > (int) \App\Models\Setting::read('cash_debt_limit', 20000)])>{{ naira($driver->cash_commission_owed) }}</td>
                <td><x-status :value="$driver->status" /></td>
            </tr>
        @empty
            <tr><td colspan="8" class="empty">No drivers match.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $drivers->links() }}
</div>
@endsection
