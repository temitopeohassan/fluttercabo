<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Partner;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class PartnerController extends Controller
{
    public function index(Request $request): View
    {
        $partners = Partner::withCount('tours')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->type, fn ($q, $t) => $q->where('type', $t))
            ->orderByRaw("case status when 'pending' then 0 else 1 end")->orderBy('name')->paginate(25)->withQueryString();

        return view('admin.partners.index', compact('partners'));
    }

    public function create(): View
    {
        return view('admin.partners.form', ['partner' => new Partner(['commission_rate' => 15, 'type' => 'tour_operator'])]);
    }

    public function store(Request $request): RedirectResponse
    {
        Partner::create($this->validated($request));

        return redirect()->route('admin.partners.index')->with('status', 'Partner added.');
    }

    public function edit(Partner $partner): View
    {
        return view('admin.partners.form', ['partner' => $partner->load('tours')]);
    }

    public function update(Request $request, Partner $partner): RedirectResponse
    {
        $data = $this->validated($request);
        $partner->update($data);
        if ($data['status'] !== 'approved') {
            $partner->tours()->update(['is_published' => false]);
        }

        return redirect()->route('admin.partners.index')->with('status', "{$partner->name} saved.");
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'name' => 'required|string|max:150',
            'type' => 'required|in:tour_operator,guide,attraction,hotel',
            'contact_name' => 'nullable|string|max:120',
            'email' => 'nullable|email|max:190',
            'phone' => 'nullable|string|max:32',
            'cac_number' => 'nullable|string|max:32',
            'status' => 'required|in:pending,approved,suspended',
            'commission_rate' => 'required|numeric|min:0|max:50',
            'bank_name' => 'nullable|string|max:60',
            'bank_account_number' => 'nullable|digits:10',
            'bank_account_name' => 'nullable|string|max:150',
        ]);
    }
}
