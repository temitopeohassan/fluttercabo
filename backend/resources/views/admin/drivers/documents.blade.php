@extends('admin.layout')
@section('title', 'Documents')
@section('content')
@php $status = request('status', 'pending'); @endphp
<div class="page-head">
    <div><h1>Driver documents</h1><p>Check each upload against the original before approving. Drivers cannot go online with expired documents.</p></div>
</div>
<div class="card">
    <div class="filters">
        <nav class="tabs" aria-label="Document status">
            @foreach (['pending' => 'To review', 'expiring' => 'Expiring or expired', 'rejected' => 'Rejected', 'approved' => 'Approved'] as $value => $label)
                <a href="{{ route('admin.documents.index', ['status' => $value]) }}" @class(['active' => $status === $value])>{{ $label }}</a>
            @endforeach
        </nav>
    </div>
    <div class="table-wrap"><table>
        <thead><tr><th>Driver</th><th>Document</th><th>Uploaded</th><th>Expires</th><th>Status</th><th>Review</th></tr></thead>
        <tbody>
        @forelse ($documents as $doc)
            <tr>
                <td><a class="strong" href="{{ route('admin.drivers.show', $doc->driver) }}">{{ $doc->driver->name }}</a><div class="muted small">{{ humanize($doc->driver->status) }}</div></td>
                <td><a href="{{ route('admin.documents.file', $doc) }}">{{ $doc->label }}</a>@if ($doc->vehicle)<div class="muted small mono">{{ $doc->vehicle->plate_number }}</div>@endif</td>
                <td class="nowrap">{{ $doc->updated_at->format('j M Y') }}</td>
                <td class="nowrap">
                    @if ($doc->expires_at){{ $doc->expires_at->format('j M Y') }} @if ($doc->isExpired())<x-status value="expired" />@endif @else <span class="muted">—</span> @endif
                </td>
                <td><x-status :value="$doc->status" /></td>
                <td>@include('admin.drivers.review-form', ['doc' => $doc])</td>
            </tr>
        @empty
            <tr><td colspan="6" class="empty">Nothing here. Nice work.</td></tr>
        @endforelse
        </tbody>
    </table></div>
    {{ $documents->links() }}
</div>
@endsection
