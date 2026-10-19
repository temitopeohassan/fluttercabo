<?php

namespace Database\Seeders;

use App\Models\Attraction;
use App\Models\Partner;
use App\Models\Tour;
use App\Models\TourCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/** Tour partners, tours with two weeks of slots, and the attraction guide. */
class ExploreSeeder extends Seeder
{
    public function run(): void
    {
        $categories = [];
        foreach ([
            ['Island Tours', 'sailing'], ['Cultural', 'museum'], ['City Tours', 'location_city'],
            ['Nightlife', 'nightlife'], ['Nature & Wildlife', 'forest'], ['Food', 'restaurant'],
        ] as $i => [$name, $icon]) {
            $categories[$name] = TourCategory::updateOrCreate(['slug' => Str::slug($name)], ['name' => $name, 'icon' => $icon, 'sort_order' => $i + 1]);
        }

        $partners = [];
        foreach ([
            ['Eko Nature Trails', 'tour_operator', 'Adaeze Nwankwo', 'bookings@ekonaturetrails.ng', '+2348021234501', 'RC 1456721', 'approved'],
            ['Funmi Island Tours', 'tour_operator', 'Funmi Ogunleye', 'hello@funmiisland.ng', '+2348021234502', 'RC 1622093', 'approved'],
            ['Eko Heritage Tours', 'tour_operator', 'Segun Akinola', 'walks@ekoheritage.ng', '+2348021234503', 'RC 1388410', 'approved'],
            ['Taste of Eko', 'tour_operator', 'Ifeoma Chukwu', 'eat@tasteofeko.ng', '+2348021234504', 'RC 1709155', 'approved'],
            ['Lagos After Dark', 'tour_operator', 'Tobi Bankole', 'nights@lagosafterdark.ng', '+2348021234505', 'RC 1811902', 'approved'],
            ['Badagry Roots Guides', 'guide', 'Kunle Mobolaji', 'kunle@badagryroots.ng', '+2348021234506', null, 'pending'],
        ] as [$name, $type, $contact, $email, $phone, $cac, $status]) {
            $partners[$name] = Partner::updateOrCreate(['name' => $name], [
                'type' => $type, 'contact_name' => $contact, 'email' => $email, 'phone' => $phone,
                'cac_number' => $cac, 'status' => $status, 'commission_rate' => 15,
                'bank_name' => 'GTBank', 'bank_account_number' => '01'.str_pad((string) (count($partners) + 1), 8, '7', STR_PAD_LEFT),
                'bank_account_name' => $name,
            ]);
        }

        $ride = ['code' => 'photo_pack', 'name' => 'Photo pack (20 edited photos)', 'price' => 5000];
        $tours = [
            [
                'Lekki Conservation Centre', 'Eko Nature Trails', 'Nature & Wildlife', 'Lekki', 15000, 240, 1, 10, 4.8, 2300, true,
                'lekki-conservation-centre.jpg', 'Lekki Conservation Centre main gate, Km 19 Lekki–Epe Expressway', 6.4413, 3.5357,
                'Walk the longest canopy walkway in Africa, spot mona monkeys and crocodiles, and learn how the reserve protects Lagos wetlands with a naturalist guide.',
                ['Meet your guide at the main gate', 'Nature trail and tree house', 'Canopy walkway (401 m)', 'Family park and picnic stop'],
                ['Entry ticket', 'Canopy walkway ticket', 'Bottled water', 'English-speaking guide'], ['Lunch', 'Hotel transfers'],
                [$ride, ['code' => 'lunch', 'name' => 'Picnic lunch', 'price' => 6000]],
            ],
            [
                'Tarkwa Bay Boat Trip', 'Funmi Island Tours', 'Island Tours', 'Lagos Harbour', 25000, 360, 2, 12, 4.7, 860, true,
                'tarkwa-bay.jpg', 'Tarzan Jetty, Maroko Road, Victoria Island', 6.4268, 3.4291,
                'Cross the harbour by speedboat to a sheltered beach for swimming and grilled fish, with life jackets and a beach umbrella waiting for you.',
                ['Board at Tarzan Jetty', 'Speedboat across Lagos Harbour', 'Free time on Tarkwa Bay', 'Grilled fish lunch', 'Return boat'],
                ['Return boat ride', 'Life jackets', 'Beach umbrella and chairs', 'Lunch'], ['Drinks', 'Water sports'],
                [$ride, ['code' => 'jet_ski', 'name' => 'Jet ski (20 minutes)', 'price' => 15000]],
            ],
            [
                'Lagos Island Heritage Walk', 'Eko Heritage Tours', 'Cultural', 'Lagos Island', 18000, 300, 1, 10, 4.9, 540, true,
                'freedom-park.jpg', 'Freedom Park, Broad Street, Lagos Island', 6.4527, 3.3937,
                'Trace the city\'s story from the old colonial prison at Freedom Park to Brazilian Quarter houses, Tinubu Square and the Cathedral Church of Christ.',
                ['Freedom Park', 'Brazilian Quarter (Popo Aguda)', 'Tinubu Square', 'Cathedral Church of Christ', 'Balogun Market edge'],
                ['Historian guide', 'Freedom Park entry', 'Bottled water', 'Small chops tasting'], ['Hotel transfers'],
                [$ride],
            ],
            [
                'Lagos Street Food Tour', 'Taste of Eko', 'Food', 'Surulere', 22000, 180, 1, 8, 4.8, 710, false,
                'lagos-street-food.jpg', 'National Stadium main gate, Surulere', 6.4997, 3.3647,
                'Taste suya, boli, amala, puff-puff and fresh zobo at the stalls locals swear by, with a guide who explains each dish and how spicy it really is.',
                ['Suya spot', 'Roadside boli and fish', 'Amala joint', 'Puff-puff and zobo'],
                ['Six tastings', 'Drinks', 'Food guide'], ['Hotel transfers'],
                [$ride],
            ],
            [
                'Victoria Island Nightlife', 'Lagos After Dark', 'Nightlife', 'Victoria Island', 30000, 300, 2, 10, 4.5, 320, false,
                'lagos-at-night.jpg', 'Eko Hotel roundabout, Victoria Island', 6.4268, 3.4290,
                'See Lagos after dark with a host: a rooftop sunset, Afrobeats live music and a well-known club, with a vetted Cabo ride between every stop.',
                ['Rooftop sunset drinks', 'Live Afrobeats bar', 'Club entry with table', 'Cabo ride home'],
                ['Host', 'Two welcome drinks', 'Club entry', 'Rides between venues'], ['Extra drinks', 'Food'],
                [$ride],
            ],
            [
                'Nike Art Gallery Visit', 'Eko Heritage Tours', 'City Tours', 'Lekki', 12000, 120, 1, 10, 4.7, 1200, false,
                'nike-art-gallery.jpg', 'Nike Art Gallery, 2 Elegushi Road, Lekki Phase 1', 6.4371, 3.4848,
                'Explore five floors of Nigerian art, from adire textiles to contemporary painting, and meet artists in the studio if they are in.',
                ['Gallery tour (five floors)', 'Adire textile demonstration', 'Time in the shop'],
                ['Guide', 'Bottled water'], ['Artwork purchases'],
                [$ride, ['code' => 'adire_class', 'name' => 'Adire dyeing class (1 hour)', 'price' => 10000]],
            ],
            [
                'Badagry Slave Route Day Trip', 'Badagry Roots Guides', 'Cultural', 'Badagry', 45000, 540, 2, 12, null, 0, false,
                null, 'Cabo pickup point, Ozumba Mbadiwe Avenue, Victoria Island', 6.4321, 3.4190,
                'A full day in Badagry: the Point of No Return, the Seriki Abass slave barracoon and the first storey building in Nigeria.',
                ['Drive to Badagry', 'Seriki Abass barracoon', 'Point of No Return', 'First storey building', 'Return drive'],
                ['Transport', 'Entry fees', 'Lunch', 'Guide'], [],
                [],
            ],
        ];

        foreach ($tours as [$title, $partner, $category, $area, $price, $mins, $minG, $maxG, $rating, $reviews, $featured, $image, $meet, $lat, $lng, $desc, $itinerary, $inc, $exc, $addons]) {
            $published = $partners[$partner]->status === 'approved';
            $tour = Tour::updateOrCreate(['slug' => Str::slug($title)], [
                'partner_id' => $partners[$partner]->id, 'tour_category_id' => $categories[$category]->id,
                'title' => $title, 'description' => $desc, 'area' => $area, 'meeting_point' => $meet,
                'meeting_lat' => $lat, 'meeting_lng' => $lng, 'duration_minutes' => $mins, 'price' => $price,
                'min_group_size' => $minG, 'max_group_size' => $maxG, 'languages' => ['English', 'Yoruba'],
                'itinerary' => $itinerary, 'inclusions' => $inc, 'exclusions' => $exc, 'addons' => $addons,
                'cancellation_policy' => 'Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.',
                'image_url' => $image ? '/images/places/'.$image : null,
                'wheelchair_accessible' => in_array($title, ['Nike Art Gallery Visit', 'Victoria Island Nightlife'], true),
                'rating' => $rating, 'reviews_count' => $reviews, 'is_featured' => $featured, 'is_published' => $published,
            ]);

            if (! $published) {
                continue;
            }

            $hours = $mins >= 300 ? [9] : [9, 14];
            for ($day = -10; $day <= 14; $day++) {
                foreach ($hours as $hour) {
                    $tour->slots()->firstOrCreate(
                        ['starts_at' => today()->addDays($day)->setTime($hour, 0)],
                        ['capacity' => $maxG],
                    );
                }
            }
        }

        $attractions = [
            ['Lekki Conservation Centre', 'Nature', 'Lekki', 'Km 19 Lekki–Epe Expressway', 6.4413, 3.5357, '8:00 – 17:00', 3000, 4.8, 2300, 'lekki-conservation-centre.jpg',
                'A 78-hectare nature reserve with the longest canopy walkway in Africa, monkeys, crocodiles and wetland birds.',
                ['Arrive before 10:00 to beat the heat', 'The canopy walkway costs extra and closes at 16:00', 'Wear trainers, the boardwalk can be slippery'],
                'Stay on the marked boardwalks. Do not feed the monkeys.'],
            ['Nike Art Gallery', 'Art', 'Lekki', '2 Elegushi Road, Lekki Phase 1', 6.4371, 3.4848, '10:00 – 18:00', 0, 4.7, 1800, 'nike-art-gallery.jpg',
                'One of the largest art galleries in West Africa, with over 8,000 works across five floors.',
                ['Entry is free, but prices for artworks are negotiable', 'Ask about the adire textile workshop'],
                'Keep bags closed in busy rooms.'],
            ['Tarkwa Bay Beach', 'Beaches', 'Lagos Harbour', 'Tarkwa Bay, reached by boat from Tarzan Jetty', 6.4011, 3.3963, 'Open daily', 2000, 4.6, 1100, 'tarkwa-bay.jpg',
                'A sheltered beach across the harbour, popular for swimming and surfing, reached only by boat.',
                ['Boats leave from Tarzan Jetty in Victoria Island', 'Bring cash for chairs and food', 'Head back before 17:00'],
                'Always wear a life jacket on the boat. Swim only where locals swim.'],
            ['Freedom Park', 'History', 'Lagos Island', 'Broad Street, Lagos Island', 6.4527, 3.3937, '9:00 – 22:00', 1000, 4.5, 940, 'freedom-park.jpg',
                'A memorial and leisure park on the site of the old Broad Street colonial prison, with live music most evenings.',
                ['Check the events board for live music nights', 'The food court is good value'],
                'Lagos Island traffic is heavy on weekdays; allow extra time.'],
            ['Lekki–Ikoyi Link Bridge', 'Landmarks', 'Ikoyi', 'Lekki–Ikoyi Link Bridge', 6.4449, 3.4395, 'Open daily', 0, 4.6, 3100, 'lekki-ikoyi-bridge.jpg',
                'A cable-stayed toll bridge linking Ikoyi and Lekki, best seen at sunset when it is lit up.',
                ['Pedestrians can walk the bridge early in the morning', 'Sunset photos are best from the Ikoyi end'],
                'Do not stop vehicles on the bridge.'],
            ['Elegushi Beach', 'Beaches', 'Lekki', 'Elegushi Royal Beach, Lekki Phase 1', 6.4322, 3.4930, '9:00 – 19:00', 2000, 4.2, 1500, null,
                'A private beach with music, food stalls, horse rides and a lively crowd at weekends.',
                ['Busiest on Sunday afternoons', 'Agree prices for chairs and horse rides first'],
                'Strong currents: do not swim far from the shore.'],
            ['Kalakuta Republic Museum', 'History', 'Ikeja', '7 Gbemisola Street, Ikeja', 6.5915, 3.3517, '10:00 – 18:00', 2000, 4.4, 420, null,
                'The former home of Afrobeat pioneer Fela Kuti, now a museum with his clothes, instruments and a rooftop bar.',
                ['Combine with an evening at the New Afrika Shrine'],
                null],
            ['Terra Kulture', 'Art', 'Victoria Island', '1376 Tiamiyu Savage Street, Victoria Island', 6.4335, 3.4229, '9:00 – 21:00', 0, 4.6, 860, null,
                'An arts centre with a theatre, gallery, bookshop and Nigerian restaurant.',
                ['Book theatre tickets in advance', 'Try the restaurant for lunch'],
                null],
        ];

        foreach ($attractions as [$name, $cat, $area, $address, $lat, $lng, $hours, $fee, $rating, $reviews, $image, $desc, $tips, $safety]) {
            Attraction::updateOrCreate(['slug' => Str::slug($name)], [
                'name' => $name, 'category' => $cat, 'area' => $area, 'description' => $desc, 'address' => $address,
                'lat' => $lat, 'lng' => $lng, 'opening_hours' => $hours, 'entry_fee' => $fee, 'visitor_tips' => $tips,
                'safety_notes' => $safety, 'image_url' => $image ? '/images/places/'.$image : null,
                'rating' => $rating, 'reviews_count' => $reviews, 'last_reviewed_on' => today()->subWeeks(3),
            ]);
        }
    }
}
