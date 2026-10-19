@extends('admin.layout')
@section('title', $ticket->subject_line)
@section('content')
@php
    $subjectLink = match ($ticket->subject_type) {
        'trip' => route('admin.trips.show', $ticket->subject_id),
        'shuttle_booking' => route('admin.shuttles.show', $ticket->subject_id),
        'tour_booking' => route('admin.tour-bookings.show', $ticket->subject_id),
        default => null,
    };
    $requesterLink = $ticket->requester_type === 'rider' ? route('admin.riders.show', $ticket->requester_id) : route('admin.drivers.show', $ticket->requester_id);
@endphp
<div class="breadcrumb"><a href="{{ route('admin.support.index') }}">Support</a> / {{ $ticket->reference }}</div>
<div class="page-head"><div class="row"><h1>{{ $ticket->subject_line }}</h1><x-status :value="$ticket->status" /><x-status :value="$ticket->priority" /></div></div>
<div class="grid grid-main">
    <div class="card">
        <div class="card-head"><h2>Conversation</h2></div>
        <div class="card-body thread">
            @foreach ($ticket->messages->sortBy('created_at') as $m)
                <div @class(['msg', 'staff' => $m->sender_type === 'admin'])>
                    <div class="meta">{{ $m->sender?->name ?? 'Unknown' }} · {{ $m->sender_type === 'admin' ? 'Cabo support' : humanize($m->sender_type) }} · {{ $m->created_at->format('j M, H:i') }}</div>
                    {!! nl2br(e($m->body)) !!}
                </div>
            @endforeach
        </div>
        <form class="card-body" method="post" action="{{ route('admin.support.reply', $ticket) }}" style="border-top:1px solid var(--line)">
            @csrf
            <div class="field"><label for="body">Reply to {{ $ticket->requester?->first_name }}</label><textarea id="body" name="body" required>{{ old('body') }}</textarea></div>
            <div class="row">
                <select name="status" aria-label="Status after reply" style="width:auto">
                    <option value="awaiting_user">Then: waiting on {{ $ticket->requester_type }}</option>
                    <option value="in_review">Then: still in review</option>
                    <option value="resolved">Then: resolved</option>
                </select>
                <button class="btn btn-primary">Send reply</button>
            </div>
            <p class="muted small" style="margin-top:8px">The {{ $ticket->requester_type }} gets an in-app notification.</p>
        </form>
    </div>
    <div class="stack">
        <div class="card"><div class="card-body">
            <dl class="dl">
                <dt>From</dt><dd><a href="{{ $requesterLink }}">{{ $ticket->requester?->name }}</a><div class="muted small">{{ humanize($ticket->requester_type) }} · {{ $ticket->requester?->phone }}</div></dd>
                <dt>Category</dt><dd>{{ humanize($ticket->category) }}</dd>
                @if ($subjectLink)<dt>About</dt><dd><a href="{{ $subjectLink }}">{{ $ticket->subject?->reference }}</a></dd>@endif
                <dt>Opened</dt><dd>{{ $ticket->created_at->format('j M Y, H:i') }}</dd>
                @if ($ticket->resolved_at)<dt>Resolved</dt><dd>{{ $ticket->resolved_at->format('j M Y, H:i') }}</dd>@endif
            </dl>
        </div></div>
        <form class="card" method="post" action="{{ route('admin.support.update', $ticket) }}">
            @csrf @method('PUT')
            <div class="card-head"><h2>Ticket</h2></div>
            <div class="card-body">
                <div class="field"><label for="t-status">Status</label><select id="t-status" name="status">@foreach (['open', 'in_review', 'awaiting_user', 'resolved'] as $s)<option value="{{ $s }}" @selected($ticket->status === $s)>{{ humanize($s) }}</option>@endforeach</select></div>
                <div class="field"><label for="priority">Priority</label><select id="priority" name="priority">@foreach (['low', 'normal', 'high', 'urgent'] as $p)<option value="{{ $p }}" @selected($ticket->priority === $p)>{{ humanize($p) }}</option>@endforeach</select></div>
                <div class="field"><label for="assigned">Assigned to</label><select id="assigned" name="assigned_admin_id"><option value="">Nobody</option>@foreach ($admins as $a)<option value="{{ $a->id }}" @selected($ticket->assigned_admin_id === $a->id)>{{ $a->name }}</option>@endforeach</select></div>
                <button class="btn btn-ghost">Update ticket</button>
            </div>
        </form>
    </div>
</div>
@endsection
