<?php

namespace Database\Seeders;

use App\Models\Driver;
use App\Models\DriverDocument;
use App\Models\FleetPartner;
use App\Models\Rider;
use Illuminate\Database\Seeder;

/** Riders with their contacts and places, and drivers with vehicles and documents. */
class PeopleSeeder extends Seeder
{
    public function run(): void
    {
        $riders = [
            // first, last, email, phone, nationality, currency, traveller type, wallet
            ['Tunde', 'Bakare', 'tunde.bakare@example.co.uk', '+447700900123', 'British', 'GBP', 'international', 25000],
            ['Amara', 'Okafor', 'amara.okafor@example.com', '+2348031234567', 'Nigerian', 'NGN', 'resident', 8000],
            ['Daniel', 'Kamau', 'daniel.kamau@example.co.ke', '+254712345678', 'Kenyan', 'USD', 'international', 0],
            ['Tolu', 'Adebayo', 'tolu.adebayo@example.com', '+2348099876543', 'Nigerian', 'NGN', 'domestic', 3500],
            ['Sarah', 'Mitchell', 'sarah.mitchell@example.com', '+14155550142', 'American', 'USD', 'international', 0],
            ['Kwame', 'Mensah', 'kwame.mensah@example.com.gh', '+233244123456', 'Ghanaian', 'USD', 'international', 12000],
            ['Chiamaka', 'Eze', 'chiamaka.eze@example.com', '+2348055512345', 'Nigerian', 'NGN', 'resident', 0],
            ['Oliver', 'Hughes', 'oliver.hughes@example.co.uk', '+447700900456', 'British', 'GBP', 'international', 40000],
            ['Aisha', 'Bello', 'aisha.bello@example.com', '+2348066623456', 'Nigerian', 'NGN', 'domestic', 1500],
            ['Marie', 'Dubois', 'marie.dubois@example.fr', '+33612345678', 'French', 'EUR', 'international', 0],
            ['Femi', 'Oyelaran', 'femi.oyelaran@example.com', '+2348077734567', 'Nigerian', 'NGN', 'resident', 6000],
            ['Grace', 'Achieng', 'grace.achieng@example.co.ke', '+254722987654', 'Kenyan', 'USD', 'international', 0],
            ['Ibrahim', 'Musa', 'ibrahim.musa@example.com', '+2348088845678', 'Nigerian', 'NGN', 'domestic', 0],
            ['Emily', 'Carter', 'emily.carter@example.ca', '+16475550199', 'Canadian', 'USD', 'international', 15000],
            ['Ngozi', 'Umeh', 'ngozi.umeh@example.com', '+2348099956789', 'Nigerian', 'NGN', 'resident', 2000],
            ['Samuel', 'Osei', 'samuel.osei@example.com.gh', '+233201234567', 'Ghanaian', 'USD', 'international', 0],
        ];

        foreach ($riders as $i => [$first, $last, $email, $phone, $nationality, $currency, $type, $wallet]) {
            $rider = Rider::updateOrCreate(['email' => $email], [
                'first_name' => $first, 'last_name' => $last, 'phone' => $phone, 'nationality' => $nationality,
                'home_currency' => $currency, 'traveller_type' => $type, 'language' => $nationality === 'French' ? 'fr' : 'en',
                'wallet_balance' => $wallet, 'loyalty_points' => mt_rand(0, 40) * 25,
                'rating' => round(mt_rand(460, 500) / 100, 2),
                'referral_code' => strtoupper(substr($first, 0, 4)).str_pad((string) ($i + 1), 4, '0', STR_PAD_LEFT),
                'status' => $email === 'ibrahim.musa@example.com' ? 'suspended' : 'active',
                'last_active_at' => now()->subHours(mt_rand(1, 240)),
                'accessibility' => $first === 'Grace' ? ['wheelchair' => true, 'assistance' => 'Needs help with a folding wheelchair'] : null,
            ]);
            $rider->created_at = now()->subDays(60 - $i * 3);
            $rider->save();
        }

        $tunde = Rider::where('email', 'tunde.bakare@example.co.uk')->first();
        $tunde->emergencyContacts()->firstOrCreate(['phone' => '+447700900987'], ['name' => 'Funmilayo Bakare', 'relationship' => 'Sister', 'share_trips_automatically' => true]);
        $tunde->emergencyContacts()->firstOrCreate(['phone' => '+2348023456789'], ['name' => 'Kunle Bakare', 'relationship' => 'Cousin']);
        foreach ([
            ['Hotel', 'Eko Hotel & Suites, Adetokunbo Ademola Street, Victoria Island', 6.4268, 3.4290],
            ['Cousin', '12 Admiralty Way, Lekki Phase 1', 6.4474, 3.4728],
            ['Work', 'Civic Centre, Ozumba Mbadiwe Avenue, Victoria Island', 6.4352, 3.4136],
        ] as [$label, $address, $lat, $lng]) {
            $tunde->savedPlaces()->firstOrCreate(['label' => $label], ['address' => $address, 'lat' => $lat, 'lng' => $lng]);
        }
        Rider::where('email', 'amara.okafor@example.com')->first()->emergencyContacts()->firstOrCreate(
            ['phone' => '+2348034445566'], ['name' => 'Chinedu Okafor', 'relationship' => 'Husband', 'share_trips_automatically' => true],
        );
        Rider::where('email', 'daniel.kamau@example.co.ke')->first()->savedPlaces()->firstOrCreate(
            ['label' => 'Hotel'], ['address' => 'The Wheatbaker, 4 Onitolo Road, Ikoyi', 'lat' => 6.4473, 'lng' => 3.4337],
        );

        $fleet = FleetPartner::orderBy('id')->get();
        $drivers = [
            // first, last, phone, status, tier, guide, make, model, year, colour, plate, seats, ride types, rating, area lat/lng
            ['Emeka', 'Nwosu', '+2348012345678', 'approved', 'standard', true, 'Toyota', 'Corolla', 2019, 'Silver', 'LND 482 KJ', 4, ['economy', 'comfort'], 4.92, 6.4300, 3.4210],
            ['Bola', 'Ajayi', '+2348012345679', 'approved', 'premium', false, 'Mercedes-Benz', 'E-Class', 2021, 'Black', 'LSR 118 AA', 4, ['premium', 'comfort'], 4.97, 6.4540, 3.4350],
            ['Chukwudi', 'Okeke', '+2348012345680', 'approved', 'standard', false, 'Toyota', 'Highlander', 2018, 'Grey', 'KJA 903 XC', 6, ['suv', 'comfort', 'economy'], 4.85, 6.4470, 3.4730],
            ['Yusuf', 'Abdullahi', '+2348012345681', 'approved', 'standard', false, 'Honda', 'Accord', 2017, 'Blue', 'EKY 552 BD', 4, ['economy', 'comfort'], 4.78, 6.5090, 3.3710],
            ['Kehinde', 'Ogunbiyi', '+2348012345682', 'approved', 'standard', true, 'Toyota', 'Camry', 2020, 'White', 'APP 731 GH', 4, ['economy', 'comfort'], 4.88, 6.4970, 3.3480],
            ['Olumide', 'Fashola', '+2348012345683', 'approved', 'premium', false, 'Lexus', 'RX 350', 2022, 'Black', 'LND 207 PR', 4, ['premium', 'suv'], 4.95, 6.4280, 3.4220],
            ['Ifeanyi', 'Obi', '+2348012345684', 'approved', 'standard', false, 'Kia', 'Rio', 2019, 'Red', 'FST 664 KL', 4, ['economy'], 4.71, 6.4550, 3.4340],
            ['Halima', 'Sani', '+2348012345685', 'approved', 'standard', false, 'Hyundai', 'Elantra', 2020, 'Silver', 'IKD 318 MN', 4, ['economy', 'comfort'], 4.90, 6.4480, 3.4710],
            ['Segun', 'Adeola', '+2348012345686', 'pending_review', 'standard', false, 'Toyota', 'Corolla', 2016, 'Gold', 'AGL 425 TU', 4, ['economy'], null, 6.5100, 3.3700],
            ['Precious', 'Etim', '+2348012345687', 'pending_review', 'standard', false, 'Toyota', 'Sienna', 2015, 'Blue', 'LSD 836 QW', 7, ['suv', 'economy'], null, 6.4960, 3.3490],
            ['Musa', 'Ibrahim', '+2348012345688', 'applicant', 'standard', false, null, null, null, null, null, null, null, null, null, null],
            ['Victor', 'Eze', '+2348012345689', 'suspended', 'standard', false, 'Nissan', 'Almera', 2014, 'White', 'MUS 109 ZX', 4, ['economy'], 4.21, 6.4290, 3.4200],
        ];

        foreach ($drivers as $i => [$first, $last, $phone, $status, $tier, $guide, $make, $model, $year, $colour, $plate, $seats, $types, $rating, $lat, $lng]) {
            $approved = $status === 'approved';
            $driver = Driver::updateOrCreate(['phone' => $phone], [
                'first_name' => $first, 'last_name' => $last,
                'email' => strtolower($first.'.'.$last).'@example.com',
                'date_of_birth' => now()->subYears(28 + $i)->subDays($i * 17)->toDateString(),
                'address' => ['Surulere', 'Ikoyi', 'Lekki', 'Yaba', 'Surulere', 'Victoria Island', 'Ikoyi', 'Lekki', 'Yaba', 'Surulere', 'Ikeja', 'Ajah'][$i].', Lagos',
                'languages' => $i % 3 === 0 ? ['English', 'Yoruba', 'Pidgin'] : ($i % 3 === 1 ? ['English', 'Igbo'] : ['English', 'Hausa']),
                'driver_type' => $i === 3 || $i === 6 ? 'fleet' : 'independent',
                'fleet_partner_id' => $i === 3 ? $fleet[0]->id : ($i === 6 ? $fleet[1]->id : null),
                'status' => $status,
                'status_reason' => $status === 'suspended' ? 'Repeated rider complaints about route deviation. Under review.' : null,
                'tier' => $tier, 'is_tour_guide' => $guide,
                'training_completed' => $approved || $status === 'suspended',
                'background_check_consent' => $status !== 'applicant',
                'inspection_at' => $status === 'pending_review' ? now()->addDays(2)->setTime(10, 0) : ($approved ? now()->subMonths(2) : null),
                'inspection_location' => $status === 'applicant' ? null : 'Cabo Driver Hub, 21 Ikorodu Road, Yaba',
                'is_online' => $approved && $i < 6,
                'current_lat' => $approved ? $lat : null, 'current_lng' => $approved ? $lng : null,
                'location_updated_at' => $approved ? now()->subMinutes($i + 1) : null,
                'preferences' => ['ride_types' => $types ?? [], 'jobs' => ['rides', 'shuttles'] + ($guide ? [2 => 'tours'] : []), 'destination_filter' => null],
                'rating' => $rating,
                'acceptance_rate' => $rating ? round(mt_rand(820, 990) / 10, 1) : 100,
                'cancellation_rate' => $rating ? round(mt_rand(5, 60) / 10, 1) : 0,
                'bank_name' => $status === 'applicant' ? null : ['GTBank', 'Access Bank', 'First Bank', 'Zenith Bank', 'UBA', 'Kuda'][$i % 6],
                'bank_account_number' => $status === 'applicant' ? null : '0'.str_pad((string) (123456789 + $i * 1111), 9, '0', STR_PAD_LEFT),
                'bank_account_name' => $status === 'applicant' ? null : strtoupper("$first $last"),
                'cash_commission_owed' => $status === 'suspended' ? 23500 : ($approved ? mt_rand(0, 12) * 500 : 0),
                'referral_code' => 'DRV'.strtoupper(substr($first, 0, 3)).str_pad((string) ($i + 1), 2, '0', STR_PAD_LEFT),
                'approved_at' => $approved || $status === 'suspended' ? now()->subMonths(3)->addDays($i) : null,
            ]);
            $driver->created_at = now()->subMonths(4)->addDays($i * 5);
            $driver->save();

            if (! $make) {
                continue;
            }

            $vehicle = $driver->vehicles()->updateOrCreate(['plate_number' => $plate], [
                'make' => $make, 'model' => $model, 'year' => $year, 'colour' => $colour, 'seats' => $seats,
                'ride_types' => $types, 'wheelchair_accessible' => $model === 'Sienna',
                'status' => $status === 'pending_review' ? 'pending' : 'approved', 'is_active' => true,
            ]);

            foreach (['drivers_licence', 'national_id', 'proof_of_address', 'lasdri_card', 'selfie', 'vehicle_licence', 'roadworthiness', 'insurance', 'vehicle_photo'] as $type) {
                $forVehicle = in_array($type, ['vehicle_licence', 'roadworthiness', 'insurance', 'vehicle_photo'], true);
                $expires = match ($type) {
                    'drivers_licence' => now()->addYears(2),
                    'lasdri_card', 'vehicle_licence', 'roadworthiness' => now()->addMonths(8),
                    // Halima's insurance runs out soon, so the panel shows an expiry warning.
                    'insurance' => $first === 'Halima' ? now()->addDays(12) : now()->addMonths(10),
                    default => null,
                };
                $docStatus = $status === 'pending_review' ? 'pending' : 'approved';
                if ($first === 'Precious' && $type === 'roadworthiness') {
                    $docStatus = 'rejected';
                }
                $driver->documents()->updateOrCreate(['type' => $type], [
                    'vehicle_id' => $forVehicle ? $vehicle->id : null,
                    'label' => DriverDocument::label($type),
                    'file_path' => "documents/driver-{$driver->id}/{$type}.jpg",
                    'status' => $docStatus,
                    'rejection_reason' => $docStatus === 'rejected' ? 'The certificate photo is blurred. Please upload a clear photo of the whole page.' : null,
                    'expires_at' => $expires?->toDateString(),
                    'reviewed_by' => $docStatus === 'pending' ? null : 1,
                    'reviewed_at' => $docStatus === 'pending' ? null : now()->subMonths(3),
                ]);
            }
        }
    }
}
