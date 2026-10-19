<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SettingController extends Controller
{
    public function edit(): View
    {
        return view('admin.settings.edit', ['groups' => Setting::orderBy('id')->get()->groupBy('group')]);
    }

    public function update(Request $request): RedirectResponse
    {
        $values = $request->validate(['settings' => 'required|array', 'settings.*' => 'nullable|string|max:255'])['settings'];
        foreach (Setting::whereIn('key', array_keys($values))->get() as $setting) {
            $setting->update(['value' => (string) ($values[$setting->key] ?? '')]);
        }

        return back()->with('status', 'Settings saved.');
    }
}
