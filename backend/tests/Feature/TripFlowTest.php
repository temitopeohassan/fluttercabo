<?php

namespace Tests\Feature;

use App\Models\Driver;
use App\Models\Rider;
use App\Models\Trip;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TripFlowTest extends TestCase
{
    use RefreshDatabase;

    private const ROUTE = [
        'pickup_lat' => 6.4268, 'pickup_lng' => 3.4290, 'pickup_address' => 'Eko Hotel & Suites',
        'dropoff_lat' => 6.4527, 'dropoff_lng' => 3.3937, 'dropoff_address' => 'Freedom Park',
    ];

    private function rider(): Rider
    {
        // Amara has no active trip in the sample data; clear any so the test starts clean.
        $rider = Rider::where('email', 'amara.okafor@example.com')->first();
        $rider->trips()->whereIn('status', Trip::ACTIVE_STATUSES)->update(['status' => 'cancelled']);

        return $rider;
    }

    private function driver(): Driver
    {
        // Bola drives a premium/comfort car and is free.
        return Driver::where('phone', '+2348012345679')->first();
    }

    public function test_fare_estimates_cover_every_ride_type(): void
    {
        Sanctum::actingAs($this->rider(), ['rider']);
        $res = $this->postJson('/api/v1/rider/fare-estimates', self::ROUTE)->assertOk();

        $this->assertCount(4, $res->json('data'));
        $economy = collect($res->json('data'))->firstWhere('ride_type', 'economy');
        $premium = collect($res->json('data'))->firstWhere('ride_type', 'premium');
        $this->assertGreaterThanOrEqual(1500, $economy['fare_total']);
        $this->assertGreaterThan($economy['fare_total'], $premium['fare_total']);
        $this->assertSame('Victoria Island', $economy['zone']);
        $this->assertSame(1.2, $economy['surge_multiplier']);
    }

    public function test_full_ride_from_request_to_rating(): void
    {
        $rider = $this->rider();
        $driver = $this->driver();
        $earningsBefore = $driver->earnings_balance;

        Sanctum::actingAs($rider, ['rider']);
        $trip = $this->postJson('/api/v1/rider/trips', self::ROUTE + ['ride_type' => 'comfort', 'payment_method' => 'card'])
            ->assertCreated()->assertJsonPath('data.status', 'requested')->json('data');
        $pin = Trip::find($trip['id'])->pin;

        Sanctum::actingAs($driver, ['driver']);
        $available = $this->getJson('/api/v1/driver/trips/available')->assertOk()->json('data');
        $this->assertContains($trip['id'], array_column($available, 'id'));
        $this->assertArrayNotHasKey('pin', $available[0]);

        $this->postJson("/api/v1/driver/trips/{$trip['id']}/accept")->assertOk()->assertJsonPath('data.status', 'accepted');
        $this->postJson("/api/v1/driver/trips/{$trip['id']}/arrive")->assertOk();
        $this->postJson("/api/v1/driver/trips/{$trip['id']}/start", ['pin' => $pin === '0000' ? '1111' : '0000'])->assertUnprocessable();
        $this->postJson("/api/v1/driver/trips/{$trip['id']}/start", ['pin' => $pin])->assertOk()->assertJsonPath('data.status', 'in_progress');
        $done = $this->postJson("/api/v1/driver/trips/{$trip['id']}/complete")->assertOk()->json('data');

        $this->assertSame('paid', $done['payment_status']);
        $this->assertSame((int) round($done['fare_total'] * 0.2), $done['commission']);
        $this->assertSame($earningsBefore + $done['driver_earnings'], $driver->fresh()->earnings_balance);

        Sanctum::actingAs($rider, ['rider']);
        $this->getJson("/api/v1/rider/trips/{$trip['id']}")->assertJsonPath('data.pin', $pin);
        $this->postJson("/api/v1/rider/trips/{$trip['id']}/rating", ['rating' => 5, 'tip' => 500])->assertOk()->assertJsonPath('data.tip', 500);
        $this->postJson("/api/v1/rider/trips/{$trip['id']}/rating", ['rating' => 4])->assertUnprocessable();
        $this->assertSame($earningsBefore + $done['driver_earnings'] + 500, $driver->fresh()->earnings_balance);
    }

    public function test_second_driver_cannot_take_an_accepted_ride(): void
    {
        Sanctum::actingAs($this->rider(), ['rider']);
        $id = $this->postJson('/api/v1/rider/trips', self::ROUTE + ['ride_type' => 'comfort', 'payment_method' => 'card'])->json('data.id');

        Sanctum::actingAs($this->driver(), ['driver']);
        $this->postJson("/api/v1/driver/trips/$id/accept")->assertOk();

        $other = Driver::where('phone', '+2348012345684')->first(); // Ifeanyi, economy only
        $other->activeVehicle->update(['ride_types' => ['economy', 'comfort']]);
        $other->update(['is_online' => true]);
        Sanctum::actingAs($other, ['driver']);
        $this->postJson("/api/v1/driver/trips/$id/accept")->assertStatus(409);
    }

    public function test_cancelling_after_the_grace_period_costs_a_fee(): void
    {
        Sanctum::actingAs($this->rider(), ['rider']);
        $id = $this->postJson('/api/v1/rider/trips', self::ROUTE + ['ride_type' => 'comfort', 'payment_method' => 'card'])->json('data.id');
        Trip::whereKey($id)->update(['driver_id' => $this->driver()->id, 'status' => 'accepted', 'accepted_at' => now()->subMinutes(5)]);

        $this->postJson("/api/v1/rider/trips/$id/cancel")->assertOk()->assertJsonPath('data.cancellation_fee', 500);
    }

    public function test_free_cancellation_before_a_driver_accepts(): void
    {
        Sanctum::actingAs($this->rider(), ['rider']);
        $id = $this->postJson('/api/v1/rider/trips', self::ROUTE + ['ride_type' => 'economy', 'payment_method' => 'card'])->json('data.id');

        $this->postJson("/api/v1/rider/trips/$id/cancel")->assertOk()->assertJsonPath('data.cancellation_fee', 0);
    }

    public function test_pickups_outside_the_service_area_are_refused(): void
    {
        Sanctum::actingAs($this->rider(), ['rider']);
        $this->postJson('/api/v1/rider/trips', array_merge(self::ROUTE, ['pickup_lat' => 6.60, 'pickup_lng' => 3.10]) + ['ride_type' => 'economy', 'payment_method' => 'card'])
            ->assertUnprocessable()->assertJsonValidationErrors('pickup_lat');
    }

    public function test_cash_ride_adds_commission_owed(): void
    {
        $driver = $this->driver();
        Sanctum::actingAs($this->rider(), ['rider']);
        $id = $this->postJson('/api/v1/rider/trips', self::ROUTE + ['ride_type' => 'comfort', 'payment_method' => 'cash'])->json('data.id');
        $trip = Trip::find($id);
        $trip->update(['driver_id' => $driver->id, 'status' => 'in_progress', 'accepted_at' => now(), 'arrived_at' => now(), 'started_at' => now()]);

        $owed = $driver->cash_commission_owed;
        Sanctum::actingAs($driver, ['driver']);
        $done = $this->postJson("/api/v1/driver/trips/$id/complete")->assertOk()->assertJsonPath('data.payment_status', 'pending')->json('data');
        $this->postJson("/api/v1/driver/trips/$id/collect-cash")->assertOk();

        $this->assertSame($owed + $done['commission'], $driver->fresh()->cash_commission_owed);
    }
}
