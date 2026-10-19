@extends('admin.layout')
@section('title', 'Pricing & zones')
@section('content')
<div class="page-head"><div><h1>Pricing and zones</h1><p>Fare = (base + per km + per minute) × pickup zone surge, never below the minimum. Riders see the price before they book.</p></div></div>

<div class="card">
    <div class="card-head"><h2>Ride types</h2><span class="muted small">Finance role can edit</span></div>
    <div class="table-wrap"><table>
        <thead><tr><th>Ride type</th><th>Seats</th><th>Base (₦)</th><th>Per km (₦)</th><th>Per min (₦)</th><th>Minimum (₦)</th><th>Active</th><th></th></tr></thead>
        <tbody>
        @foreach ($rideTypes as $type)
            <tr>
                    <td><form id="rt-{{ $type->id }}" method="post" action="{{ route('admin.ride-types.update', $type) }}">@csrf @method('PUT')</form><input form="rt-{{ $type->id }}" type="text" name="name" value="{{ $type->name }}" aria-label="Name" style="min-width:110px"><input form="rt-{{ $type->id }}" type="hidden" name="description" value="{{ $type->description }}"><div class="muted small mono">{{ $type->code }}</div></td>
                    <td><input form="rt-{{ $type->id }}" type="number" name="seats" value="{{ $type->seats }}" min="1" max="8" aria-label="Seats" style="width:70px"></td>
                    <td><input form="rt-{{ $type->id }}" type="number" name="base_fare" value="{{ $type->base_fare }}" min="0" aria-label="Base fare" style="width:100px"></td>
                    <td><input form="rt-{{ $type->id }}" type="number" name="per_km" value="{{ $type->per_km }}" min="0" aria-label="Per km" style="width:90px"></td>
                    <td><input form="rt-{{ $type->id }}" type="number" name="per_minute" value="{{ $type->per_minute }}" min="0" aria-label="Per minute" style="width:90px"></td>
                    <td><input form="rt-{{ $type->id }}" type="number" name="minimum_fare" value="{{ $type->minimum_fare }}" min="0" aria-label="Minimum fare" style="width:100px"></td>
                    <td><input form="rt-{{ $type->id }}" type="checkbox" name="is_active" value="1" @checked($type->is_active) aria-label="Active" style="width:18px;height:18px;accent-color:var(--green)"></td>
                    <td><button form="rt-{{ $type->id }}" class="btn btn-ghost btn-sm">Save</button></td>
            </tr>
        @endforeach
        </tbody>
    </table></div>
    <div class="card-body muted small" style="border-top:1px solid var(--line)">
        Example: a 10 km, 27 minute Economy ride costs {{ naira(max($rideTypes->first()->minimum_fare, $rideTypes->first()->base_fare + 10 * $rideTypes->first()->per_km + 27 * $rideTypes->first()->per_minute)) }} with no surge. Waiting time, stops, tolls and cancellation fees are in <a href="{{ route('admin.settings') }}">Settings</a>.
    </div>
</div>

<div class="card" style="margin-top:16px">
    <div class="card-head"><h2>Zones and surge</h2><span class="muted small">A pickup inside a service area can be booked. Surge applies to pickups in the zone.</span></div>
    <div class="table-wrap"><table>
        <thead><tr><th>Zone</th><th>Centre lat</th><th>Centre lng</th><th>Radius km</th><th>Surge ×</th><th>Service area</th><th>Active</th><th></th></tr></thead>
        <tbody>
        @foreach ($zones as $zone)
            <tr>
                    <td><form id="zone-{{ $zone->id }}" method="post" action="{{ route('admin.zones.update', $zone) }}">@csrf @method('PUT')</form><input form="zone-{{ $zone->id }}" type="text" name="name" value="{{ $zone->name }}" aria-label="Name" style="min-width:160px"></td>
                    <td><input form="zone-{{ $zone->id }}" type="text" name="center_lat" value="{{ $zone->center_lat }}" aria-label="Latitude" style="width:110px"></td>
                    <td><input form="zone-{{ $zone->id }}" type="text" name="center_lng" value="{{ $zone->center_lng }}" aria-label="Longitude" style="width:110px"></td>
                    <td><input form="zone-{{ $zone->id }}" type="number" step="0.1" name="radius_km" value="{{ $zone->radius_km }}" aria-label="Radius" style="width:80px"></td>
                    <td><input form="zone-{{ $zone->id }}" type="number" step="0.05" min="1" max="3" name="surge_multiplier" value="{{ $zone->surge_multiplier }}" aria-label="Surge" style="width:80px" @style(['border-color:var(--orange)' => $zone->surge_multiplier > 1])></td>
                    <td><input form="zone-{{ $zone->id }}" type="checkbox" name="is_service_area" value="1" @checked($zone->is_service_area) aria-label="Service area" style="width:18px;height:18px;accent-color:var(--green)"></td>
                    <td><input form="zone-{{ $zone->id }}" type="checkbox" name="is_active" value="1" @checked($zone->is_active) aria-label="Active" style="width:18px;height:18px;accent-color:var(--green)"></td>
                    <td class="nowrap"><button form="zone-{{ $zone->id }}" class="btn btn-ghost btn-sm">Save</button></td>
            </tr>
        @endforeach
        <tr>
                <td><form id="zone-new" method="post" action="{{ route('admin.zones.store') }}">@csrf</form><input form="zone-new" type="text" name="name" placeholder="New zone" aria-label="New zone name" required></td>
                <td><input form="zone-new" type="text" name="center_lat" placeholder="6.4500" aria-label="Latitude" style="width:110px" required></td>
                <td><input form="zone-new" type="text" name="center_lng" placeholder="3.4000" aria-label="Longitude" style="width:110px" required></td>
                <td><input form="zone-new" type="number" step="0.1" name="radius_km" value="3" aria-label="Radius" style="width:80px" required></td>
                <td><input form="zone-new" type="number" step="0.05" name="surge_multiplier" value="1" aria-label="Surge" style="width:80px" required></td>
                <td><input form="zone-new" type="checkbox" name="is_service_area" value="1" checked aria-label="Service area" style="width:18px;height:18px;accent-color:var(--green)"></td>
                <td><input form="zone-new" type="checkbox" name="is_active" value="1" checked aria-label="Active" style="width:18px;height:18px;accent-color:var(--green)"></td>
                <td><button form="zone-new" class="btn btn-primary btn-sm">Add</button></td>
        </tr>
        </tbody>
    </table></div>
</div>
@endsection
