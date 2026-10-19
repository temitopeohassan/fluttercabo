<?php

namespace Tests\Feature;

use App\Models\Rider;
use App\Models\Tour;
use App\Models\TourBooking;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TourBookingTest extends TestCase
{
    use RefreshDatabase;

    private function setUpBooking(): array
    {
        $rider = Rider::where('email', 'tunde.bakare@example.co.uk')->first();
        $tour = Tour::where('slug', 'lekki-conservation-centre')->first();
        $slot = $tour->slots()->where('starts_at', '>', now()->addDays(3))->where('booked', 0)->orderBy('starts_at')->first();
        Sanctum::actingAs($rider, ['rider']);

        return [$rider, $tour, $slot];
    }

    public function test_public_tour_listing_and_slots(): void
    {
        $this->getJson('/api/v1/tours?category=nature-wildlife')->assertOk()->assertJsonPath('data.0.title', 'Lekki Conservation Centre');
        $this->getJson('/api/v1/tours/lekki-conservation-centre/slots')->assertOk()->assertJsonStructure(['data' => [['id', 'starts_at', 'capacity', 'booked', 'remaining']]]);
        $this->getJson('/api/v1/tours/badagry-slave-route-day-trip')->assertNotFound();
    }

    public function test_booking_with_addons_and_promo_charges_the_wallet(): void
    {
        [$rider, $tour, $slot] = $this->setUpBooking();
        $balance = $rider->wallet_balance;

        $res = $this->postJson('/api/v1/rider/tour-bookings', [
            'tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 1,
            'addons' => ['photo_pack'], 'promo_code' => 'EKOTOURS', 'payment_method' => 'wallet',
        ])->assertCreated();

        // ₦15,000 ticket + ₦5,000 photo pack − ₦2,000 promo.
        $this->assertSame(18000, $res->json('data.total'));
        $this->assertSame($balance - 18000, $rider->fresh()->wallet_balance);
        $this->assertSame(1, $slot->fresh()->booked);
    }

    public function test_wallet_must_cover_the_booking(): void
    {
        [, $tour, $slot] = $this->setUpBooking();
        $this->postJson('/api/v1/rider/tour-bookings', ['tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 2, 'payment_method' => 'wallet'])
            ->assertUnprocessable()->assertJsonValidationErrors('payment_method');
        $this->assertSame(0, $slot->fresh()->booked);
    }

    public function test_cannot_book_more_places_than_are_left(): void
    {
        [, $tour, $slot] = $this->setUpBooking();
        $slot->update(['booked' => $slot->capacity - 2]);

        $this->postJson('/api/v1/rider/tour-bookings', ['tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 3, 'payment_method' => 'card'])
            ->assertUnprocessable()->assertJsonPath('errors.guests.0', 'Only 2 places are left for this time.');
        $this->postJson('/api/v1/rider/tour-bookings', ['tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 2, 'payment_method' => 'card'])
            ->assertCreated();
        $this->postJson('/api/v1/rider/tour-bookings', ['tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 1, 'payment_method' => 'card'])
            ->assertUnprocessable()->assertJsonPath('errors.guests.0', 'This time is fully booked.');
    }

    public function test_early_cancellation_refunds_in_full_and_frees_places(): void
    {
        [$rider, $tour, $slot] = $this->setUpBooking();
        $rider->update(['wallet_balance' => 50000]);
        $id = $this->postJson('/api/v1/rider/tour-bookings', ['tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 2, 'payment_method' => 'wallet'])
            ->assertCreated()->json('data.id');
        $balance = $rider->fresh()->wallet_balance;

        $this->postJson("/api/v1/rider/tour-bookings/$id/cancel")->assertOk()->assertJsonPath('refund', 30000);
        $this->assertSame($balance + 30000, $rider->fresh()->wallet_balance);
        $this->assertSame(0, $slot->fresh()->booked);
    }

    public function test_reviews_need_a_check_in(): void
    {
        [, $tour, $slot] = $this->setUpBooking();
        $id = $this->postJson('/api/v1/rider/tour-bookings', ['tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => 1, 'payment_method' => 'card'])->json('data.id');

        $this->postJson("/api/v1/rider/tour-bookings/$id/review", ['rating' => 5])->assertUnprocessable();

        TourBooking::whereKey($id)->update(['status' => 'completed', 'checked_in_at' => now()]);
        $this->postJson("/api/v1/rider/tour-bookings/$id/review", ['rating' => 5, 'comment' => 'Superb'])->assertCreated();
        $this->postJson("/api/v1/rider/tour-bookings/$id/review", ['rating' => 4])->assertUnprocessable();
    }
}
