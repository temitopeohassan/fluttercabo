<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\SupportTicket;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SupportController extends Controller
{
    public function index(Request $request): View
    {
        $status = $request->status ?? 'active';
        $tickets = SupportTicket::with('requester', 'assignee:id,name')->withCount('messages')
            ->when($status === 'active', fn ($q) => $q->where('status', '!=', 'resolved'), fn ($q) => $q->when($status !== 'all', fn ($q) => $q->where('status', $status)))
            ->when($request->category, fn ($q, $c) => $q->where('category', $c))
            ->when($request->boolean('mine'), fn ($q) => $q->where('assigned_admin_id', $request->user()->id))
            ->orderByRaw("case priority when 'urgent' then 0 when 'high' then 1 when 'normal' then 2 else 3 end")->latest()
            ->paginate(30)->withQueryString();

        return view('admin.support.index', compact('tickets', 'status'));
    }

    public function show(SupportTicket $ticket): View
    {
        $ticket->load('requester', 'subject', 'messages.sender', 'assignee');

        return view('admin.support.show', ['ticket' => $ticket, 'admins' => Admin::where('is_active', true)->orderBy('name')->get()]);
    }

    public function reply(Request $request, SupportTicket $ticket): RedirectResponse
    {
        $data = $request->validate(['body' => 'required|string|max:5000', 'status' => 'required|in:in_review,awaiting_user,resolved']);
        $admin = $request->user();

        $ticket->messages()->create(['sender_type' => 'admin', 'sender_id' => $admin->id, 'body' => $data['body']]);
        $ticket->update([
            'status' => $data['status'],
            'assigned_admin_id' => $ticket->assigned_admin_id ?? $admin->id,
            'resolved_at' => $data['status'] === 'resolved' ? now() : null,
        ]);
        $ticket->requester?->appNotifications()->create([
            'type' => 'support', 'title' => "Reply on {$ticket->reference}", 'body' => str($data['body'])->limit(120)->toString(),
            'data' => ['support_ticket_id' => $ticket->id],
        ]);

        return back()->with('status', 'Reply sent.');
    }

    public function update(Request $request, SupportTicket $ticket): RedirectResponse
    {
        $data = $request->validate([
            'status' => 'required|in:open,in_review,awaiting_user,resolved',
            'priority' => 'required|in:low,normal,high,urgent',
            'assigned_admin_id' => 'nullable|exists:admins,id',
        ]);
        $ticket->update($data + ['resolved_at' => $data['status'] === 'resolved' ? ($ticket->resolved_at ?? now()) : null]);

        return back()->with('status', 'Ticket updated.');
    }
}
