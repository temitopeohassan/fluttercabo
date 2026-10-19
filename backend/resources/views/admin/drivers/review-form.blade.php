<form method="post" action="{{ route('admin.documents.review', $doc) }}" class="row" style="gap:6px">
    @csrf
    @if ($doc->status !== 'approved')
        <button class="btn btn-ghost btn-sm" name="status" value="approved">Approve</button>
    @endif
    @if ($doc->status !== 'rejected')
        <input type="text" name="rejection_reason" placeholder="Reason if rejecting" aria-label="Rejection reason" style="width:180px;min-height:32px;padding:4px 10px">
        <button class="btn btn-danger btn-sm" name="status" value="rejected">Reject</button>
    @endif
</form>
