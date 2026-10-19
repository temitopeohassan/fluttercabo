<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

/** Control panel accounts. Super admins only. */
class AdminUserController extends Controller
{
    public function index(): View
    {
        return view('admin.admins.index', ['admins' => Admin::orderBy('name')->get()]);
    }

    public function create(): View
    {
        return view('admin.admins.form', ['admin' => new Admin(['role' => 'support', 'is_active' => true])]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:190|unique:admins',
            'role' => ['required', Rule::in(Admin::ROLES)],
            'password' => ['required', Password::min(8)],
        ]);
        Admin::create($data + ['is_active' => true]);

        return redirect()->route('admin.admins.index')->with('status', 'Admin account created.');
    }

    public function edit(Admin $admin): View
    {
        return view('admin.admins.form', compact('admin'));
    }

    public function update(Request $request, Admin $admin): RedirectResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => ['required', 'email', 'max:190', Rule::unique('admins')->ignore($admin->id)],
            'role' => ['required', Rule::in(Admin::ROLES)],
            'password' => ['nullable', Password::min(8)],
        ]);
        if (empty($data['password'])) {
            unset($data['password']);
        }
        $active = $request->boolean('is_active');
        if ($admin->is($request->user()) && (! $active || $data['role'] !== 'super_admin')) {
            return back()->with('error', 'You cannot deactivate yourself or remove your own super admin role.');
        }
        $admin->update($data + ['is_active' => $active]);

        return redirect()->route('admin.admins.index')->with('status', "{$admin->name} saved.");
    }
}
