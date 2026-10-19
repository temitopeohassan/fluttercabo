@extends('admin.layout')
@section('title', 'Booking '.$booking->reference)
@section('content')
<div class="breadcrumb"><a href="{{ route('admin.tour-bookings.index') }}">Tour bookings</a> / {{ $booking->reference }}</div>
<div class="page-head">
    <div class="row"><h1 class="mono" style="font-size:22px">{{ $booking->reference }}</h1><x-status :value="$booking->status" /></div>
    @if ($booking->status === 'confirmed')
        <form method="post" action="{{ route('admin.tour-bookings.check-in', $booking) }}">@csrf<button class="btn btn-yellow">Check guest in</button></form>
    @endif
</div>
<div class="grid grid-main">
    <div class="stack">
        <div class="card"><div class="card-head"><h2>{{ $booking->tour->title }}</h2><a href="{{ route('admin.tours.show', $booking->tour) }}">View tour</a></div><div class="card-body">
            <dl class="dl">
                <dt>Date</dt><dd>{{ $booking->slot->starts_at->format('l j F Y, H:i') }}</dd>
                <dt>Meet at</dt><dd>{{ $booking->tour->meeting_point }}</dd>
                <dt>Guests</dt><dd>{{ $booking->guests }}</dd>
                <dt>Partner</dt><dd>{{ $booking->tour->partner->name }}</dd>
                <dt>Cabo guide</dt><dd>{{ $booking->slot->guide?->name ?? 'None' }}</dd>
                @if ($booking->company_name)<dt>Company</dt><dd>{{ $booking->company_name }}</dd>@endif
                <dt>Checked in</dt><dd>{{ $booking->checked_in_at?->format('j M Y, H:i') ?? 'Not yet' }}</dd>
                <dt>QR token</dt><dd class="mono small">{{ $booking->qr_token }}</dd>
            </dl>
        </div></div>
        @if ($booking->review)
        <div class="card"><div class="card-head"><h2>Review</h2>
            <form method="post" action="{{ route('admin.tour-bookings.review', $booking) }}">@csrf<button class="btn btn-ghost btn-sm">{{ $booking->review->is_visible ? 'Hide review' : 'Show review' }}</button></form>
        </div><div class="card-body">
            <div class="strong">{{ str_repeat('★', $booking->review->rating) }}{{ str_repeat('☆', 5 - $booking->review->rating) }}</div>
            <p>{{ $booking->review->comment }}</p>
            @if ($booking->review->highlights)<ul class="pill-list">@foreach ($booking->review->highlights as $h)<li>{{ $h }}</li>@endforeach</ul>@endif
        </div></div>
        @endif
    </div>
    <div class="stack">
        <div class="card"><div class="card-head"><h2>Payment</h2><x-status :value="$booking->payment_status" /></div><div class="card-body">
            <dl class="dl">
                <dt>Tickets</dt><dd>{{ $booking->guests }} × {{ naira($booking->tour->price) }} = {{ naira($booking->subtotal) }}</dd>
                @foreach ($booking->addons ?? [] as $a)<dt>{{ $a['name'] }}</dt><dd>{{ naira($a['price']) }}</dd>@endforeach
                @if ($booking->ride_addon_price)<dt>Ride to the tour</dt><dd>{{ naira($booking->ride_addon_price) }}</dd>@endif
                @if ($booking->discount)<dt>Discount</dt><dd>−{{ naira($booking->discount) }} {{ $booking->promoCode?->code }}</dd>@endif
                <dt class="strong">Total</dt><dd class="strong">{{ naira($booking->total) }}</dd>
                <dt>Method</dt><dd>{{ humanize($booking->payment_method) }}</dd>
                @if ($booking->refund_amount)<dt>Refunded</dt><dd>{{ naira($booking->refund_amount) }}</dd>@endif
            </dl>
        </div></div>
        <div class="card"><div class="card-body">
            <dl class="dl"><dt>Rider</dt><dd><a href="{{ route('admin.riders.show', $booking->rider) }}">{{ $booking->rider->name }}</a><div class="muted small">{{ $booking->rider->email }}<br>{{ $booking->rider->phone }}</div></dd></dl>
        </div></div>
        @if (in_array($booking->status, ['confirmed', 'checked_in']))
        <div class="card"><div class="card-head"><h2>Cancel booking</h2></div>
            <form class="card-body" method="post" action="{{ route('admin.tour-bookings.cancel', $booking) }}">
                @csrf
                <div class="field"><label for="refund_amount">Refund (₦)</label><input id="refund_amount" type="number" name="refund_amount" min="0" max="{{ $booking->total }}" value="{{ $booking->total }}" required></div>
                <button class="btn btn-danger" onclick="return confirm('Cancel this booking and issue the refund?')">Cancel and refund</button>
            </form>
        </div>
        @endif
    </div>
</div>
@endsection
