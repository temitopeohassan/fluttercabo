<?php

namespace Tests\Feature;

use App\Models\Rider;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_rider_signs_up_with_a_phone_code(): void
    {
        $this->postJson('/api/v1/rider/auth/otp', ['identifier' => '0803 123 0000'])
            ->assertOk()->assertJsonPath('identifier', '+2348031230000')->assertJsonPath('debug_code', '123456');

        $res = $this->postJson('/api/v1/rider/auth/verify', ['identifier' => '08031230000', 'code' => '123456'])
            ->assertCreated()->assertJsonPath('is_new', true);

        $this->withToken($res->json('token'))->getJson('/api/v1/rider/me')->assertOk()->assertJsonPath('data.phone', '+2348031230000');
    }

    public function test_wrong_code_fails_and_codes_are_single_use(): void
    {
        $this->postJson('/api/v1/rider/auth/otp', ['identifier' => 'tunde@example.co.uk']);
        $this->postJson('/api/v1/rider/auth/verify', ['identifier' => 'tunde@example.co.uk', 'code' => '000000'])->assertUnprocessable();
        $this->postJson('/api/v1/rider/auth/verify', ['identifier' => 'tunde@example.co.uk', 'code' => '123456'])->assertCreated();
        $this->postJson('/api/v1/rider/auth/verify', ['identifier' => 'tunde@example.co.uk', 'code' => '123456'])->assertUnprocessable();
    }

    public function test_tokens_only_open_their_own_app(): void
    {
        $this->postJson('/api/v1/driver/auth/otp', ['identifier' => '+2348099990000']);
        $driverToken = $this->postJson('/api/v1/driver/auth/verify', ['identifier' => '+2348099990000', 'code' => '123456'])->json('token');

        $this->withToken($driverToken)->getJson('/api/v1/rider/me')->assertForbidden();
        $this->withToken($driverToken)->getJson('/api/v1/driver/me')->assertOk()->assertJsonPath('data.status', 'applicant');
    }

    public function test_suspended_riders_cannot_sign_in(): void
    {
        Rider::create(['phone' => '+2348000000001', 'status' => 'suspended']);
        $this->postJson('/api/v1/rider/auth/otp', ['identifier' => '+2348000000001']);
        $this->postJson('/api/v1/rider/auth/verify', ['identifier' => '+2348000000001', 'code' => '123456'])->assertForbidden();
    }

    public function test_unauthenticated_requests_get_json_401(): void
    {
        $this->getJson('/api/v1/rider/trips')->assertUnauthorized();
    }

    public function test_demo_code_also_works_in_production_when_set(): void
    {
        $this->app['env'] = 'production';
        config(['cabo.demo_otp' => '123456']);

        $this->postJson('/api/v1/rider/auth/otp', ['identifier' => '+2348031239999'])->assertOk()->assertJsonPath('debug_code', '123456');
        $this->postJson('/api/v1/rider/auth/verify', ['identifier' => '+2348031239999', 'code' => '123456'])->assertCreated();
    }

    public function test_without_a_demo_code_codes_are_random_and_emailed(): void
    {
        \Illuminate\Support\Facades\Mail::fake();
        config(['cabo.demo_otp' => null]);

        $this->postJson('/api/v1/rider/auth/otp', ['identifier' => 'guest@example.com'])->assertOk()->assertJsonMissingPath('debug_code');
        $this->postJson('/api/v1/rider/auth/verify', ['identifier' => 'guest@example.com', 'code' => '123456'])->assertUnprocessable();
    }

    public function test_places_search_and_host_performance(): void
    {
        $this->getJson('/api/v1/places?q=nike')->assertOk()->assertJsonPath('data.0.name', 'Nike Art Gallery')->assertJsonPath('data.0.kind', 'attraction');
        $this->assertGreaterThan(10, count($this->getJson('/api/v1/places')->json('data')));

        \Laravel\Sanctum\Sanctum::actingAs(\App\Models\Driver::where('phone', '+2348012345678')->first(), ['driver']);
        $this->getJson('/api/v1/driver/performance')->assertOk()
            ->assertJsonStructure(['data' => ['rating', 'rating_breakdown' => ['5', '1'], 'acceptance_rate', 'completed_trips', 'tier']]);
    }
}
