<?php

namespace Tests\Feature;

use App\Models\Driver;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DriverOnlineTest extends TestCase
{
    use RefreshDatabase;

    private function goOnline(Driver $driver)
    {
        Sanctum::actingAs($driver, ['driver']);

        return $this->postJson('/api/v1/driver/status', ['online' => true, 'lat' => 6.43, 'lng' => 3.42]);
    }

    public function test_approved_driver_with_valid_documents_can_go_online(): void
    {
        $driver = Driver::where('phone', '+2348012345679')->first();
        $this->goOnline($driver)->assertOk()->assertJsonPath('data.is_online', true);
    }

    public function test_driver_pending_review_cannot_go_online(): void
    {
        $driver = Driver::where('status', 'pending_review')->first();
        $this->goOnline($driver)->assertForbidden()->assertJsonFragment(['Your account is pending review.']);
    }

    public function test_new_applicant_cannot_go_online(): void
    {
        $this->goOnline(Driver::where('status', 'applicant')->first())->assertForbidden();
    }

    public function test_expired_document_blocks_going_online(): void
    {
        $driver = Driver::where('phone', '+2348012345679')->first();
        $driver->documents()->where('type', 'insurance')->update(['expires_at' => now()->subDay()]);

        $this->goOnline($driver)->assertForbidden()->assertJsonFragment(['Insurance certificate has expired.']);
    }

    public function test_cash_debt_over_the_limit_blocks_going_online(): void
    {
        $driver = Driver::where('phone', '+2348012345679')->first();
        $driver->update(['cash_commission_owed' => 25000]);

        $this->goOnline($driver)->assertForbidden();
    }

    public function test_instant_cash_out_deducts_fee_and_cash_owed(): void
    {
        $driver = Driver::where('phone', '+2348012345679')->first();
        $driver->update(['earnings_balance' => 30000, 'cash_commission_owed' => 4000]);
        Sanctum::actingAs($driver, ['driver']);

        $this->postJson('/api/v1/driver/payouts/instant', ['amount' => 27000])->assertUnprocessable();
        $this->postJson('/api/v1/driver/payouts/instant', ['amount' => 20000])
            ->assertCreated()->assertJsonPath('data.amount', 19700)->assertJsonPath('data.fee', 300)->assertJsonPath('balance', 6000);
        $this->assertSame(0, $driver->fresh()->cash_commission_owed);
    }
}
