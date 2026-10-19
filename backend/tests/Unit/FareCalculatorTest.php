<?php

namespace Tests\Unit;

use App\Models\RideType;
use App\Models\Zone;
use App\Services\FareCalculator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FareCalculatorTest extends TestCase
{
    use RefreshDatabase;

    private function economy(): RideType
    {
        return RideType::where('code', 'economy')->first();
    }

    public function test_short_rides_pay_the_minimum_fare(): void
    {
        // Ikoyi has no surge.
        $fare = app(FareCalculator::class)->estimate($this->economy(), 6.4549, 3.4346, 6.4555, 3.4350);
        $this->assertSame(1500, $fare['fare_total']);
    }

    public function test_surge_multiplies_the_pickup_zone_fare(): void
    {
        $calc = app(FareCalculator::class);
        $yaba = Zone::where('name', 'Yaba')->first();
        $normal = $calc->estimate($this->economy(), 6.5095, 3.3711, 6.4281, 3.4219);

        $yaba->update(['surge_multiplier' => 1.5]);
        $surged = $calc->estimate($this->economy(), 6.5095, 3.3711, 6.4281, 3.4219);

        $raw = $normal['fare_base'] + $normal['fare_distance'] + $normal['fare_time'];
        $this->assertSame($raw, $normal['fare_total'] - $normal['tolls']);
        $this->assertSame((int) round($raw * 1.5) + $surged['tolls'], $surged['fare_total']);
    }

    public function test_crossing_the_lekki_toll_gate_adds_the_toll(): void
    {
        $fare = app(FareCalculator::class)->estimate($this->economy(), 6.4281, 3.4219, 6.4474, 3.4728);
        $this->assertSame(250, $fare['tolls']);
    }

    public function test_commission_is_twenty_percent(): void
    {
        $this->assertSame(['commission' => 800, 'driver_earnings' => 3200], app(FareCalculator::class)->split(4000));
    }
}
