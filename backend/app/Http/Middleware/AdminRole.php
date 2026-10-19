<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Limits an admin route to the given roles. Super admins can do everything. */
class AdminRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $admin = $request->user();
        abort_unless($admin && ($admin->isSuperAdmin() || in_array($admin->role, $roles, true)), 403, 'Your role cannot do this.');

        return $next($request);
    }
}
