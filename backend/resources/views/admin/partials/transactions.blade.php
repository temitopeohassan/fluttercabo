<div class="table-wrap"><table>
    <thead><tr><th>Reference</th><th>Description</th><th>Type</th><th>Method</th><th class="right">Amount</th><th>Date</th></tr></thead>
    <tbody>
    @forelse ($transactions as $tx)
        <tr>
            <td class="mono">{{ $tx->reference }}</td>
            <td>{{ $tx->description }}</td>
            <td>{{ humanize($tx->type) }}</td>
            <td>{{ humanize($tx->method) }}</td>
            <td class="right nowrap" style="color: {{ $tx->direction === 'credit' ? 'var(--green)' : 'inherit' }}">{{ $tx->direction === 'credit' ? '+' : '−' }}{{ naira($tx->amount) }}</td>
            <td class="nowrap muted">{{ $tx->created_at->format('j M Y, H:i') }}</td>
        </tr>
    @empty
        <tr><td colspan="6" class="empty">No transactions.</td></tr>
    @endforelse
    </tbody>
</table></div>
