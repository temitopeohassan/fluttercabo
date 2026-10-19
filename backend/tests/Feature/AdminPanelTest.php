<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Driver;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeded_admin_can_sign_in(): void
    {
        $this->post('/admin/login', ['email' => 'admin@caboapp.online', 'password' => 'password123!'])
            ->assertRedirect('/admin');

        $this->assertAuthenticatedAs(Admin::where('email', 'admin@caboapp.online')->first());
        $this->get('/admin')->assertOk()->assertSee('Needs attention');
    }

    public function test_wrong_password_is_rejected(): void
    {
        $this->post('/admin/login', ['email' => 'admin@caboapp.online', 'password' => 'wrong'])
            ->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    public function test_guests_are_sent_to_login(): void
    {
        $this->get('/admin/drivers')->assertRedirect('/admin/login');
    }

    public function test_every_admin_page_loads(): void
    {
        $this->actingAs(Admin::where('role', 'super_admin')->first());
        $params = ['rider' => 1, 'driver' => 1, 'document' => 1, 'trip' => 1, 'shuttle' => 1, 'tour' => 1, 'booking' => 1, 'partner' => 1, 'attraction' => 1, 'promoCode' => 1, 'ticket' => 1, 'admin' => 1];

        $checked = 0;
        foreach (Route::getRoutes() as $route) {
            if (! in_array('GET', $route->methods()) || ! str_starts_with($route->uri(), 'admin') || in_array($route->getName(), ['admin.login', 'admin.documents.file'])) {
                continue;
            }
            $url = route($route->getName(), array_intersect_key($params, array_flip($route->parameterNames())));
            $this->get($url)->assertOk();
            $checked++;
        }
        $this->assertGreaterThan(30, $checked);
    }

    public function test_roles_limit_actions(): void
    {
        $support = Admin::where('role', 'support')->first();
        $this->actingAs($support)->get('/admin/settings')->assertForbidden();
        $this->actingAs($support)->post('/admin/drivers/9/status', ['status' => 'approved'])->assertForbidden();

        $ops = Admin::where('role', 'operations')->first();
        $this->actingAs($ops)->post('/admin/drivers/9/status', ['status' => 'approved'])->assertRedirect();
        $this->assertSame('approved', Driver::find(9)->status);
    }

    public function test_waitlist_exports_csv(): void
    {
        $this->actingAs(Admin::first())->get('/admin/waitlist/export')
            ->assertOk()->assertHeader('content-type', 'text/csv; charset=utf-8');
    }
}
