<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Attraction;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class AttractionController extends Controller
{
    public function index(Request $request): View
    {
        $attractions = Attraction::when($request->q, fn ($q, $s) => $q->where('name', 'like', "%$s%"))
            ->orderBy('name')->paginate(25)->withQueryString();

        return view('admin.attractions.index', compact('attractions'));
    }

    public function create(): View
    {
        return view('admin.attractions.form', ['attraction' => new Attraction(['is_published' => true])]);
    }

    public function store(Request $request): RedirectResponse
    {
        Attraction::create($this->validated($request));

        return redirect()->route('admin.attractions.index')->with('status', 'Attraction added.');
    }

    public function edit(Attraction $attraction): View
    {
        return view('admin.attractions.form', compact('attraction'));
    }

    public function update(Request $request, Attraction $attraction): RedirectResponse
    {
        $attraction->update($this->validated($request, $attraction));

        return redirect()->route('admin.attractions.index')->with('status', "{$attraction->name} saved.");
    }

    public function destroy(Attraction $attraction): RedirectResponse
    {
        $attraction->wishlistedBy()->delete();
        $attraction->delete();

        return redirect()->route('admin.attractions.index')->with('status', 'Attraction deleted.');
    }

    private function validated(Request $request, ?Attraction $attraction = null): array
    {
        $data = $request->validate([
            'name' => 'required|string|max:150',
            'slug' => ['nullable', 'alpha_dash', 'max:160', Rule::unique('attractions')->ignore($attraction?->id)],
            'category' => 'required|string|max:40',
            'area' => 'required|string|max:80',
            'description' => 'required|string|max:5000',
            'address' => 'nullable|string|max:255',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'opening_hours' => 'nullable|string|max:80',
            'entry_fee' => 'required|integer|min:0',
            'visitor_tips' => 'nullable|string|max:3000',
            'safety_notes' => 'nullable|string|max:2000',
            'image_url' => 'nullable|string|max:255',
            'is_published' => 'boolean',
        ]);
        $data['slug'] = $data['slug'] ?: Str::slug($data['name']);
        $data['visitor_tips'] = collect(preg_split('/\r?\n/', (string) $data['visitor_tips']))->map(fn ($l) => trim($l))->filter()->values()->all();
        $data['is_published'] = $request->boolean('is_published');
        $data['last_reviewed_on'] = today();

        return $data;
    }
}
