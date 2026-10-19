<?php

namespace Database\Seeders;

use App\Models\FleetPartner;
use App\Models\PromoCode;
use App\Models\RideType;
use App\Models\Setting;
use App\Models\Zone;
use Illuminate\Database\Seeder;

/** Pricing, zones, settings and promo codes. */
class PlatformSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([
            ['economy', 'Economy', 'Affordable everyday rides', 4, 700, 120, 20, 1500],
            ['comfort', 'Comfort', 'Newer cars with extra legroom', 4, 1000, 170, 28, 2200],
            ['suv', 'SUV', 'Room for six and their luggage', 6, 1500, 240, 38, 3200],
            ['premium', 'Premium', 'Top-rated drivers in executive cars', 4, 2200, 360, 55, 4800],
        ] as $i => [$code, $name, $desc, $seats, $base, $km, $min, $minimum]) {
            RideType::updateOrCreate(['code' => $code], [
                'name' => $name, 'description' => $desc, 'seats' => $seats, 'base_fare' => $base,
                'per_km' => $km, 'per_minute' => $min, 'minimum_fare' => $minimum, 'sort_order' => $i + 1,
            ]);
        }

        // Pilot service areas from the PRD, plus the airport.
        foreach ([
            ['Victoria Island', 6.4281, 3.4219, 3.0, 1.2],
            ['Ikoyi', 6.4549, 3.4346, 3.0, 1.0],
            ['Lekki', 6.4474, 3.4728, 6.0, 1.0],
            ['Yaba', 6.5095, 3.3711, 3.0, 1.0],
            ['Surulere', 6.4969, 3.3481, 3.5, 1.0],
            ['Murtala Muhammed Airport', 6.5774, 3.3212, 2.5, 1.0],
        ] as [$name, $lat, $lng, $radius, $surge]) {
            Zone::updateOrCreate(['name' => $name], ['center_lat' => $lat, 'center_lng' => $lng, 'radius_km' => $radius, 'surge_multiplier' => $surge]);
        }

        foreach ([
            ['commission_rate', '20', 'Platform commission (%)', 'pricing'],
            ['free_waiting_minutes', '5', 'Free waiting time (minutes)', 'pricing'],
            ['waiting_fee_per_minute', '50', 'Waiting fee per minute after free time (₦)', 'pricing'],
            ['airport_free_waiting_minutes', '60', 'Airport pickup free waiting time (minutes)', 'pricing'],
            ['stop_fee', '300', 'Fee per extra stop (₦)', 'pricing'],
            ['lekki_toll', '250', 'Lekki toll gate charge (₦)', 'pricing'],
            ['rider_cancellation_fee', '500', 'Rider cancellation fee after driver accepts (₦)', 'pricing'],
            ['free_cancellation_minutes', '2', 'Free cancellation window after acceptance (minutes)', 'pricing'],
            ['cash_debt_limit', '20000', 'Driver cash commission limit before going offline (₦)', 'drivers'],
            ['instant_cashout_fee_percent', '1.5', 'Instant cash-out fee (%)', 'drivers'],
            ['minimum_cashout', '5000', 'Minimum instant cash-out (₦)', 'drivers'],
            ['weekly_payout_day', 'Tuesday', 'Weekly payout day', 'drivers'],
            ['gbp_rate', '2000', 'Display exchange rate: ₦ per £1', 'currency'],
            ['usd_rate', '1550', 'Display exchange rate: ₦ per $1', 'currency'],
            ['eur_rate', '1700', 'Display exchange rate: ₦ per €1', 'currency'],
            ['tour_free_cancellation_hours', '24', 'Free tour cancellation up to (hours before)', 'tours'],
            ['tour_ride_addon_price', '4000', 'Ride to the tour add-on (₦ per booking)', 'tours'],
            ['support_phone', '+234 201 330 2226', 'Support phone', 'general'],
            ['support_email', 'help@caboapp.online', 'Support email', 'general'],
            ['emergency_number', '112', 'Emergency number shown in the safety centre', 'general'],
        ] as [$key, $value, $label, $group]) {
            Setting::updateOrCreate(['key' => $key], ['value' => $value, 'label' => $label, 'group' => $group]);
        }

        foreach ([
            ['WELCOME20', '20% off your first booking, up to ₦5,000', 'percent', 20, 5000, 'all', true, null],
            ['AIRPORT10', '10% off airport shuttles', 'percent', 10, 3000, 'shuttle', false, 500],
            ['EKOTOURS', '₦2,000 off any tour', 'fixed', 2000, null, 'tour', false, 1000],
            ['RIDE500', '₦500 off a ride', 'fixed', 500, null, 'ride', false, null],
        ] as [$code, $desc, $type, $value, $max, $applies, $first, $limit]) {
            PromoCode::updateOrCreate(['code' => $code], [
                'description' => $desc, 'discount_type' => $type, 'value' => $value, 'max_discount' => $max,
                'applies_to' => $applies, 'first_booking_only' => $first, 'usage_limit' => $limit,
                'starts_at' => now()->subMonth()->startOfDay(), 'ends_at' => now()->addMonths(6)->endOfDay(),
            ]);
        }

        foreach ([
            ['Eko Fleet Services', 'Surulere', 'Bisi Lawal', '+2348031110001', 'hello@ekofleet.ng'],
            ['Island Wheels Ltd', 'Victoria Island', 'Chidi Obi', '+2348031110002', 'ops@islandwheels.ng'],
        ] as [$name, $area, $contact, $phone, $email]) {
            FleetPartner::updateOrCreate(['name' => $name], ['area' => $area, 'contact_name' => $contact, 'phone' => $phone, 'email' => $email]);
        }
    }
}
