<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class PromoCodeController extends Controller
{
    public function index(): View
    {
        return view('admin.promo-codes.index', ['codes' => PromoCode::orderByDesc('is_active')->orderBy('code')->paginate(30)]);
    }

    public function create(): View
    {
        return view('admin.promo-codes.form', ['code' => new PromoCode(['discount_type' => 'percent', 'applies_to' => 'all', 'is_active' => true])]);
    }

    public function store(Request $request): RedirectResponse
    {
        PromoCode::create($this->validated($request));

        return redirect()->route('admin.promo-codes.index')->with('status', 'Promo code created.');
    }

    public function edit(PromoCode $promoCode): View
    {
        return view('admin.promo-codes.form', ['code' => $promoCode]);
    }

    public function update(Request $request, PromoCode $promoCode): RedirectResponse
    {
        $promoCode->update($this->validated($request, $promoCode));

        return redirect()->route('admin.promo-codes.index')->with('status', "{$promoCode->code} saved.");
    }

    private function validated(Request $request, ?PromoCode $code = null): array
    {
        $request->merge(['code' => strtoupper((string) $request->code)]);

        return $request->validate([
            'code' => ['required', 'alpha_num', 'max:32', Rule::unique('promo_codes')->ignore($code?->id)],
            'description' => 'required|string|max:255',
            'discount_type' => 'required|in:percent,fixed',
            'value' => ['required', 'integer', 'min:1', $request->discount_type === 'percent' ? 'max:100' : 'max:1000000'],
            'max_discount' => 'nullable|integer|min:1',
            'applies_to' => 'required|in:all,ride,shuttle,tour',
            'usage_limit' => 'nullable|integer|min:1',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date|after:starts_at',
        ]) + [
            'first_booking_only' => $request->boolean('first_booking_only'),
            'is_active' => $request->boolean('is_active'),
        ];
    }
}
