<?php

namespace Tests\Feature;

use App\Models\WaitlistSignup;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WaitlistTest extends TestCase
{
    use RefreshDatabase;

    public function test_website_form_joins_the_waitlist(): void
    {
        $payload = ['name' => 'Chloe Adams', 'email' => 'Chloe@Example.co.uk', 'source' => 'website'];

        $this->postJson('/api/v1/waitlist', $payload)->assertCreated()->assertJsonPath('message', "You're on the list. We'll email you when Cabo launches.");
        $this->postJson('/api/v1/waitlist', $payload)->assertOk();

        $this->assertSame(1, WaitlistSignup::where('email', 'chloe@example.co.uk')->count());
    }

    public function test_name_and_valid_email_are_required(): void
    {
        $this->postJson('/api/v1/waitlist', ['email' => 'not-an-email'])->assertUnprocessable()->assertJsonValidationErrors(['name', 'email']);
    }

    public function test_other_origins_are_allowed(): void
    {
        $this->withHeaders(['Origin' => 'https://caboapp.online'])
            ->postJson('/api/v1/waitlist', ['name' => 'A', 'email' => 'a@example.com'])
            ->assertHeader('Access-Control-Allow-Origin', '*');
    }
}
