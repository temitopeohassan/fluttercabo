<?php

namespace Database\Seeders;

use App\Models\Driver;
use App\Models\Payout;
use App\Models\Review;
use App\Models\Rider;
use App\Models\RideType;
use App\Models\ShuttleBooking;
use App\Models\SosAlert;
use App\Models\SupportTicket;
use App\Models\Tour;
use App\Models\TourBooking;
use App\Models\Trip;
use App\Models\WaitlistSignup;
use App\Services\FareCalculator;
use App\Services\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/** A month of trips, shuttles, tour bookings, payments, payouts and support. */
class ActivitySeeder extends Seeder
{
    private const PLACES = [
        ['Eko Hotel & Suites, Victoria Island', 6.4268, 3.4290],
        ['Lekki Conservation Centre, Lekki', 6.4413, 3.5357],
        ['Nike Art Gallery, Lekki Phase 1', 6.4371, 3.4848],
        ['Freedom Park, Lagos Island', 6.4527, 3.3937],
        ['Tarzan Jetty, Victoria Island', 6.4268, 3.4291],
        ['The Palms Shopping Mall, Lekki', 6.4359, 3.4510],
        ['Ikoyi Club 1938, Ikoyi', 6.4520, 3.4300],
        ['Yaba Tech, Yaba', 6.5180, 3.3740],
        ['National Stadium, Surulere', 6.4997, 3.3647],
        ['Terra Kulture, Victoria Island', 6.4335, 3.4229],
        ['Landmark Beach, Oniru', 6.4210, 3.4430],
        ['The Wheatbaker, Ikoyi', 6.4473, 3.4337],
        ['Admiralty Way, Lekki Phase 1', 6.4474, 3.4728],
        ['Shoprite Surulere, Adeniran Ogunsanya', 6.4930, 3.3570],
    ];

    public function run(): void
    {
        $fares = app(FareCalculator::class);
        $riders = Rider::where('status', 'active')->orderBy('id')->get();
        $drivers = Driver::where('status', 'approved')->with('activeVehicle')->orderBy('id')->get();
        $types = RideType::orderBy('sort_order')->get()->keyBy('code');
        $tunde = $riders->firstWhere('email', 'tunde.bakare@example.co.uk');
        $emeka = $drivers->firstWhere('phone', '+2348012345678');

        // Completed and cancelled trips over the last 30 days.
        for ($n = 0; $n < 90; $n++) {
            $rider = $n % 5 === 0 ? $tunde : $riders[mt_rand(0, $riders->count() - 1)];
            $driver = $n % 4 === 0 ? $emeka : $drivers[mt_rand(0, $drivers->count() - 1)];
            $vehicle = $driver->activeVehicle;
            $code = collect($vehicle->ride_types)->random();
            [$from, $to] = $this->route();
            $estimate = $fares->estimate($types[$code], $from[1], $from[2], $to[1], $to[2]);
            $requested = now()->subDays(mt_rand(0, 29))->setTime(mt_rand(6, 22), mt_rand(0, 59));
            $cancelled = mt_rand(1, 100) <= 8;
            $method = ['card', 'card', 'card', 'wallet', 'cash', 'bank_transfer'][mt_rand(0, 5)];
            $tip = ! $cancelled && mt_rand(1, 100) <= 30 ? [200, 500, 1000][mt_rand(0, 2)] : 0;
            $split = $fares->split($estimate['fare_total']);

            $trip = Trip::create([
                'rider_id' => $rider->id, 'driver_id' => $driver->id, 'vehicle_id' => $vehicle->id,
                'ride_type_id' => $types[$code]->id,
                'status' => $cancelled ? 'cancelled' : 'completed',
                'pickup_address' => $from[0], 'pickup_lat' => $from[1], 'pickup_lng' => $from[2],
                'dropoff_address' => $to[0], 'dropoff_lat' => $to[1], 'dropoff_lng' => $to[2],
                'pin' => str_pad((string) mt_rand(0, 9999), 4, '0', STR_PAD_LEFT),
                'distance_km' => $estimate['distance_km'], 'duration_minutes' => $estimate['duration_minutes'],
                'surge_multiplier' => $estimate['surge_multiplier'],
                'fare_base' => $estimate['fare_base'], 'fare_distance' => $estimate['fare_distance'],
                'fare_time' => $estimate['fare_time'], 'tolls' => $estimate['tolls'],
                'fare_total' => $cancelled ? 0 : $estimate['fare_total'], 'tip' => $tip,
                'commission' => $cancelled ? 0 : $split['commission'],
                'driver_earnings' => $cancelled ? 0 : $split['driver_earnings'] + $tip,
                'cancellation_fee' => $cancelled ? 500 : 0,
                'payment_method' => $method, 'payment_status' => 'paid',
                'cancelled_by' => $cancelled ? 'rider' : null,
                'cancellation_reason' => $cancelled ? 'Plans changed' : null,
                'driver_rating' => ! $cancelled && mt_rand(1, 100) <= 85 ? [5, 5, 5, 4, 5, 4, 3][mt_rand(0, 6)] : null,
                'rider_rating' => ! $cancelled && mt_rand(1, 100) <= 70 ? [5, 5, 4][mt_rand(0, 2)] : null,
                'driver_feedback' => $n === 0 ? 'Emeka was very friendly and the car was spotless.' : null,
                'accepted_at' => $requested->copy()->addMinutes(1),
                'arrived_at' => $cancelled ? null : $requested->copy()->addMinutes(7),
                'started_at' => $cancelled ? null : $requested->copy()->addMinutes(9),
                'completed_at' => $cancelled ? null : $requested->copy()->addMinutes(9 + $estimate['duration_minutes']),
                'cancelled_at' => $cancelled ? $requested->copy()->addMinutes(4) : null,
                'created_at' => $requested, 'updated_at' => $requested,
            ]);

            $charge = $cancelled ? 500 : $estimate['fare_total'] + $tip;
            $tx = Wallet::record($rider, 'charge', 'debit', $charge, $method,
                $cancelled ? "Cancellation fee {$trip->reference}" : "Ride {$trip->reference}", $trip);
            $tx->forceFill(['created_at' => $trip->completed_at ?? $trip->cancelled_at])->save();

            if (! $cancelled) {
                // Cash trips leave commission owed, which PeopleSeeder sets per driver.
                if ($method !== 'cash') {
                    $earn = Wallet::record($driver, 'driver_earning', 'credit', $split['driver_earnings'] + $tip, 'system', "Earnings {$trip->reference}", $trip);
                    $earn->forceFill(['created_at' => $trip->completed_at])->save();
                }
            }
        }

        // Tunde's ride happening right now: Emeka is on the way.
        $estimate = $fares->estimate($types['comfort'], 6.4268, 3.4290, 6.4371, 3.4848);
        $split = $fares->split($estimate['fare_total']);
        Trip::create([
            'rider_id' => $tunde->id, 'driver_id' => $emeka->id, 'vehicle_id' => $emeka->activeVehicle->id,
            'ride_type_id' => $types['comfort']->id, 'status' => 'accepted',
            'pickup_address' => 'Eko Hotel & Suites, Victoria Island', 'pickup_lat' => 6.4268, 'pickup_lng' => 3.4290,
            'dropoff_address' => 'Nike Art Gallery, Lekki Phase 1', 'dropoff_lat' => 6.4371, 'dropoff_lng' => 3.4848,
            'pin' => '4821', 'distance_km' => $estimate['distance_km'], 'duration_minutes' => $estimate['duration_minutes'],
            'surge_multiplier' => $estimate['surge_multiplier'], 'fare_base' => $estimate['fare_base'],
            'fare_distance' => $estimate['fare_distance'], 'fare_time' => $estimate['fare_time'], 'tolls' => $estimate['tolls'],
            'fare_total' => $estimate['fare_total'], 'commission' => $split['commission'], 'driver_earnings' => $split['driver_earnings'],
            'payment_method' => 'card', 'payment_status' => 'authorised', 'share_token' => Str::random(24),
            'accepted_at' => now()->subMinutes(2),
        ]);

        // A request waiting for a driver, and a scheduled ride.
        foreach ([['requested', null], ['scheduled', now()->addDay()->setTime(7, 30)]] as $k => [$status, $at]) {
            $rider = $riders[1 + $k];
            [$from, $to] = $this->route();
            $estimate = $fares->estimate($types['economy'], $from[1], $from[2], $to[1], $to[2]);
            Trip::create([
                'rider_id' => $rider->id, 'ride_type_id' => $types['economy']->id, 'status' => $status, 'scheduled_at' => $at,
                'pickup_address' => $from[0], 'pickup_lat' => $from[1], 'pickup_lng' => $from[2],
                'dropoff_address' => $to[0], 'dropoff_lat' => $to[1], 'dropoff_lng' => $to[2],
                'pin' => str_pad((string) mt_rand(0, 9999), 4, '0', STR_PAD_LEFT),
                'distance_km' => $estimate['distance_km'], 'duration_minutes' => $estimate['duration_minutes'],
                'surge_multiplier' => $estimate['surge_multiplier'], 'fare_base' => $estimate['fare_base'],
                'fare_distance' => $estimate['fare_distance'], 'fare_time' => $estimate['fare_time'], 'tolls' => $estimate['tolls'],
                'fare_total' => $estimate['fare_total'], 'payment_method' => 'card', 'payment_status' => 'pending',
            ]);
        }

        // Airport shuttles.
        $shuttles = [
            [$tunde, 'airport_pickup', 'BA75', 'Terminal 2 (International)', now()->addDays(3)->setTime(16, 35), 'Eko Hotel & Suites, Victoria Island', 6.4268, 3.4290, 'comfort', 2, 2, 1, 22000, $emeka, 'driver_assigned'],
            [$riders->firstWhere('first_name', 'Daniel'), 'airport_dropoff', 'KQ533', 'Terminal 2 (International)', now()->addDays(5)->setTime(23, 15), 'The Wheatbaker, Ikoyi', 6.4473, 3.4337, 'comfort', 1, 1, 1, 22000, null, 'confirmed'],
            [$riders->firstWhere('first_name', 'Sarah'), 'airport_pickup', 'DL54', 'Terminal 2 (International)', now()->subDays(6)->setTime(15, 20), 'Lagos Continental Hotel, Victoria Island', 6.4247, 3.4115, 'economy', 1, 2, 0, 18000, $drivers[1], 'completed'],
            [$riders->firstWhere('first_name', 'Oliver'), 'airport_pickup', 'VS411', 'Terminal 2 (International)', now()->addDays(1)->setTime(6, 5), 'Admiralty Way, Lekki Phase 1', 6.4474, 3.4728, 'premium', 2, 3, 2, 45000, $drivers[5], 'driver_assigned'],
            [$riders->firstWhere('first_name', 'Kwame'), 'airport_dropoff', 'AW124', 'Domestic Terminal (MMA2)', now()->addDays(2)->setTime(11, 0), 'Radisson Blu Anchorage, Victoria Island', 6.4337, 3.4167, 'economy', 1, 1, 0, 16000, null, 'confirmed'],
        ];
        foreach ($shuttles as [$rider, $direction, $flight, $terminal, $flightTime, $address, $lat, $lng, $code, $pax, $large, $small, $price, $driver, $status]) {
            $pickup = $direction === 'airport_pickup' ? $flightTime->copy()->addMinutes(45) : $flightTime->copy()->subHours(4);
            $booking = ShuttleBooking::create([
                'rider_id' => $rider->id, 'driver_id' => $status === 'confirmed' ? null : $driver?->id,
                'direction' => $direction, 'terminal' => $terminal, 'flight_number' => $flight, 'flight_time' => $flightTime,
                'flight_status' => $status === 'completed' ? 'landed' : 'scheduled', 'pickup_at' => $pickup,
                'address' => $address, 'lat' => $lat, 'lng' => $lng, 'ride_type_id' => $types[$code]->id,
                'passengers' => $pax, 'large_bags' => $large, 'small_bags' => $small, 'price' => $price,
                'driver_payout' => (int) round($price * 0.8),
                'meeting_point' => $direction === 'airport_pickup' ? 'Arrivals hall exit, by the Cabo sign at Pillar 3' : null,
                'name_board' => $direction === 'airport_pickup' ? strtoupper($rider->last_name) : null,
                'payment_method' => 'card', 'payment_status' => 'paid', 'status' => $status,
                'driver_assigned_at' => $status === 'confirmed' ? null : now()->subDay(),
                'created_at' => now()->subDays(8),
            ]);
            Wallet::record($rider, 'charge', 'debit', $price, 'card', "Airport shuttle {$booking->reference}", $booking);
        }

        // Tour bookings: past ones checked in and reviewed, upcoming ones confirmed.
        $tours = Tour::where('is_published', true)->with('slots')->get();
        $comments = [
            'Our guide knew every tree and monkey by name. The canopy walk is not for the faint-hearted!',
            'Brilliant day out. Well organised and the driver was waiting when we finished.',
            'Loved every minute. Bring sunscreen.',
            'Great value and a really friendly group.',
            'Good tour but it started 20 minutes late.',
            'The highlight of my trip to Lagos.',
        ];
        $b = 0;
        foreach ($tours as $tour) {
            foreach ($tour->slots->sortBy('starts_at')->values() as $s => $slot) {
                if ($s % 3 !== 0) {
                    continue;
                }
                $rider = $b % 4 === 0 ? $tunde : $riders[mt_rand(0, $riders->count() - 1)];
                $guests = min(mt_rand(1, 3), $slot->capacity - $slot->booked);
                $past = $slot->starts_at->isPast();
                $subtotal = $tour->price * $guests;
                $method = ['card', 'card', 'wallet', 'bank_transfer'][mt_rand(0, 3)];
                $booking = TourBooking::create([
                    'rider_id' => $rider->id, 'tour_id' => $tour->id, 'tour_slot_id' => $slot->id, 'guests' => $guests,
                    'subtotal' => $subtotal, 'addons' => [], 'addons_total' => 0, 'discount' => 0, 'total' => $subtotal,
                    'payment_method' => $method, 'payment_status' => 'paid',
                    'status' => $past ? 'completed' : 'confirmed', 'qr_token' => Str::random(32),
                    'checked_in_at' => $past ? $slot->starts_at->copy()->subMinutes(10) : null,
                    'created_at' => $slot->starts_at->copy()->subDays(mt_rand(2, 9)),
                ]);
                $slot->increment('booked', $guests);
                Wallet::record($rider, $method === 'wallet' ? 'wallet_payment' : 'charge', 'debit', $subtotal, $method, "Tour {$booking->reference}", $booking);
                if ($past && mt_rand(1, 100) <= 70) {
                    Review::create([
                        'rider_id' => $rider->id, 'tour_id' => $tour->id, 'tour_booking_id' => $booking->id,
                        'rating' => [5, 5, 5, 4, 4, 3][mt_rand(0, 5)], 'comment' => $comments[mt_rand(0, count($comments) - 1)],
                        'highlights' => [['Great guide', 'Good value', 'Well organised', 'Safe'][mt_rand(0, 3)]],
                    ])->forceFill(['created_at' => $slot->starts_at->copy()->addHours(6)])->save();
                }
                $b++;
            }
        }

        // Driver payouts for the last four weeks.
        foreach ($drivers as $driver) {
            for ($w = 1; $w <= 4; $w++) {
                $start = now()->startOfWeek()->subWeeks($w);
                $amount = mt_rand(45, 140) * 1000;
                $payout = Payout::create([
                    'driver_id' => $driver->id, 'type' => 'weekly', 'amount' => $amount, 'fee' => 0,
                    'period_start' => $start->toDateString(), 'period_end' => $start->copy()->endOfWeek()->toDateString(),
                    'bank_name' => $driver->bank_name, 'bank_account_number' => $driver->bank_account_number,
                    'status' => 'paid', 'processed_by' => 4, 'paid_at' => $start->copy()->addDays(8)->setTime(10, 0),
                    'created_at' => $start->copy()->addDays(7),
                ]);
                Wallet::record($driver, 'payout', 'debit', $amount, 'bank_transfer', "Weekly payout {$payout->reference}", $payout)
                    ->forceFill(['created_at' => $payout->paid_at])->save();
            }
            $driver->update(['earnings_balance' => mt_rand(20, 90) * 1000]);
        }
        $emeka->refresh()->update(['earnings_balance' => 48500]);
        Payout::create([
            'driver_id' => $emeka->id, 'type' => 'instant', 'amount' => 19700, 'fee' => 300,
            'bank_name' => $emeka->bank_name, 'bank_account_number' => $emeka->bank_account_number, 'status' => 'pending',
        ]);

        // Wallet top-ups for riders with a balance.
        foreach ($riders->where('wallet_balance', '>', 0) as $rider) {
            Wallet::record($rider, 'wallet_topup', 'credit', $rider->wallet_balance + 10000, 'card', 'Wallet top-up');
        }

        // Support tickets.
        $lastTrip = Trip::where('rider_id', $tunde->id)->where('status', 'completed')->latest('completed_at')->first();
        $tickets = [
            [$tunde, $lastTrip, 'lost_item', 'Left my sunglasses in the car', 'in_review', 'normal', [
                ['rider', 'Hi, I think I left my Ray-Ban sunglasses on the back seat after my ride this afternoon.'],
                ['admin', 'Sorry to hear that, Tunde. We have messaged your driver and will update you within the hour.'],
            ]],
            [$riders->firstWhere('first_name', 'Amara'), null, 'overcharge', 'Charged twice for one ride', 'open', 'high', [
                ['rider', 'My card was charged twice for the same trip to Ikoyi. Please refund one of them.'],
            ]],
            [$riders->firstWhere('first_name', 'Marie'), null, 'refund', 'Refund for cancelled tour', 'resolved', 'normal', [
                ['rider', 'The tour was cancelled due to rain. When will I get my refund?'],
                ['admin', 'We have issued a full refund to your card. It can take 3–5 working days to appear.'],
            ]],
            [$emeka, null, 'payout', 'Instant cash-out not received', 'open', 'normal', [
                ['driver', 'I requested an instant cash-out of ₦19,700 but it has not arrived in my GTBank account.'],
            ]],
            [$drivers[3], null, 'rider_behaviour', 'Rider damaged seat cover', 'awaiting_user', 'low', [
                ['driver', 'A rider spilled a drink on my back seat last night.'],
                ['admin', 'Please send us photos of the damage and the receipt for cleaning.'],
            ]],
        ];
        foreach ($tickets as $i => [$requester, $subject, $category, $line, $status, $priority, $messages]) {
            $ticket = SupportTicket::create([
                'requester_type' => $requester->getMorphClass(), 'requester_id' => $requester->id,
                'subject_type' => $subject?->getMorphClass(), 'subject_id' => $subject?->id,
                'category' => $category, 'subject_line' => $line, 'status' => $status, 'priority' => $priority,
                'assigned_admin_id' => $status === 'open' ? null : 3,
                'resolved_at' => $status === 'resolved' ? now()->subDays(2) : null,
                'created_at' => now()->subDays(4 - min($i, 3))->subHours($i),
            ]);
            foreach ($messages as $m => [$who, $body]) {
                $ticket->messages()->create([
                    'sender_type' => $who === 'admin' ? 'admin' : $requester->getMorphClass(),
                    'sender_id' => $who === 'admin' ? 3 : $requester->id,
                    'body' => $body,
                ])->forceFill(['created_at' => $ticket->created_at->copy()->addMinutes(20 * $m)])->save();
            }
        }

        // One resolved SOS and one open for the operations team to see.
        SosAlert::create([
            'raised_by_type' => 'rider', 'raised_by_id' => $riders->firstWhere('first_name', 'Chiamaka')->id,
            'trip_id' => Trip::where('status', 'completed')->inRandomOrder()->value('id'),
            'lat' => 6.4552, 'lng' => 3.4335, 'address' => 'Falomo Bridge, Ikoyi', 'status' => 'resolved', 'handled_by' => 2,
            'acknowledged_at' => now()->subDays(9), 'resolved_at' => now()->subDays(9)->addMinutes(18),
            'notes' => 'Rider felt unwell. Driver took her to Reddington Hospital. Followed up next day; all fine.',
            'created_at' => now()->subDays(9),
        ]);
        SosAlert::create([
            'raised_by_type' => 'driver', 'raised_by_id' => $drivers[2]->id,
            'lat' => 6.4410, 'lng' => 3.4920, 'address' => 'Lekki–Epe Expressway near Chevron', 'status' => 'open',
            'created_at' => now()->subMinutes(6),
        ]);

        // Inbox notifications.
        foreach ([
            [$tunde, 'trip', 'Emeka is on the way', 'Silver Toyota Corolla · LND 482 KJ · arriving in 4 min'],
            [$tunde, 'shuttle', 'Airport pickup confirmed', 'BA75 arriving '.now()->addDays(3)->format('D j M').' at 16:35. Emeka will meet you at Pillar 3.'],
            [$tunde, 'promo', '20% off your first tour', 'Use WELCOME20 at checkout. Up to ₦5,000 off.'],
            [$emeka, 'trip', 'New trip request', 'Pickup at Eko Hotel & Suites, Victoria Island'],
            [$emeka, 'payout', 'Weekly payout sent', 'Your weekly earnings have been paid to GTBank.'],
            [$emeka, 'document', 'Insurance expires soon', 'Upload your new insurance certificate before it expires.'],
        ] as [$to, $type, $title, $body]) {
            $to->appNotifications()->create(['type' => $type, 'title' => $title, 'body' => $body]);
        }

        // Website waitlist sign-ups.
        foreach ([
            ['Chloe Adams', 'chloe.adams@example.co.uk'], ['Jide Martins', 'jide.martins@example.com'],
            ['Hannah Schmidt', 'hannah.schmidt@example.de'], ['Uche Nnamdi', 'uche.nnamdi@example.com'],
            ['Priya Patel', 'priya.patel@example.co.uk'], ['Tomiwa Ade', 'tomiwa.ade@example.com'],
            ['Lucas Silva', 'lucas.silva@example.com.br'], ['Zainab Yusuf', 'zainab.yusuf@example.com'],
            ['James O\'Neill', 'james.oneill@example.ie'], ['Efua Asante', 'efua.asante@example.com.gh'],
            ['Kemi Coker', 'kemi.coker@example.com'], ['Driver Lead', 'drive.with.cabo@example.com'],
        ] as $i => [$name, $email]) {
            WaitlistSignup::create(['name' => $name, 'email' => $email, 'source' => $i === 11 ? 'driver' : 'website', 'invited_at' => $i < 3 ? now()->subDays(5) : null])
                ->forceFill(['created_at' => now()->subDays(20 - $i)])->save();
        }

        // Ratings on tours with seeded reviews keep their marketing totals; recalculate drivers from trips.
        foreach ($drivers as $driver) {
            $avg = Trip::where('driver_id', $driver->id)->whereNotNull('driver_rating')->avg('driver_rating');
            if ($avg && $driver->id !== $emeka->id) {
                $driver->update(['rating' => round($avg, 2)]);
            }
        }
    }

    private function route(): array
    {
        $from = self::PLACES[mt_rand(0, count(self::PLACES) - 1)];
        do {
            $to = self::PLACES[mt_rand(0, count(self::PLACES) - 1)];
        } while ($to === $from);

        return [$from, $to];
    }
}
