@props(['value'])
@php
    $colour = match ($value) {
        'completed', 'approved', 'paid', 'active', 'resolved', 'succeeded', 'checked_in', 'landed', 'on_time', 'credit' => 'green',
        'pending', 'pending_review', 'scheduled', 'awaiting_user', 'processing', 'authorised', 'partially_refunded' => 'yellow',
        'requested', 'accepted', 'arrived', 'in_progress', 'driver_assigned', 'confirmed', 'in_review', 'acknowledged' => 'blue',
        'cancelled', 'rejected', 'suspended', 'failed', 'no_show', 'open', 'urgent', 'expired', 'delayed', 'refunded', 'debit' => 'red',
        'high', 'applicant' => 'orange',
        default => '',
    };
@endphp
<span {{ $attributes->merge(['class' => "badge $colour"]) }}>{{ humanize($value) }}</span>
