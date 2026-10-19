# Cabo backend

Laravel 13 (PHP 8.3) and MySQL. One application serves:

- **The admin control panel** at `/admin`: a server-rendered Blade app for the operations, support and finance teams.
- **The REST API** at `/api/v1` for the rider app, the driver app and the website's waitlist form.

## Admin sign-in

| Email | Password | Role |
| --- | --- | --- |
| `admin@caboapp.online` | `password123!` | Super admin |

The seeder also creates `ops@caboapp.online`, `support@caboapp.online` and `finance@caboapp.online`, all with the same password, so you can try each role.

> **Change these passwords before going live.** Sign in, open your name in the top bar, and change the password. A super admin can reset the other accounts under **Admin users**, or deactivate the sample ones.

## Set up

You need PHP 8.3 with `pdo_mysql`, Composer, and MySQL 8 or MariaDB 10.6+.

```bash
cd backend
composer install
cp .env.example .env          # then set DB_DATABASE, DB_USERNAME and DB_PASSWORD
php artisan key:generate
```

Create the database, then load it **one** of two ways:

```bash
mysql -u root -p -e "CREATE DATABASE cabo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

# A. Import the SQL dump (tables and sample data)
mysql -u root -p cabo < database/cabo.sql

# B. Or build it with Laravel
php artisan migrate --seed
```

Run it:

```bash
php artisan serve             # http://localhost:8000/admin
```

In production, point the web server at `backend/public`, set `APP_ENV=production`, `APP_DEBUG=false` and `APP_URL`, and run `php artisan config:cache route:cache view:cache`.

### The SQL dump

`database/cabo.sql` creates all 39 tables and fills them with Lagos sample data:

- 16 riders, including Tunde Bakare, a visitor from the UK with a ride in progress.
- 12 drivers, including Emeka Nwosu (silver Toyota Corolla 2019, LND 482 KJ). Two drivers are waiting for review, one is a new applicant and one is suspended.
- A month of trips, airport shuttles, tour bookings and reviews, with the payments, payouts, support tickets and SOS alerts that go with them.
- 7 tours with slots for the next two weeks, and 8 attractions.
- The 4 ride types, 6 zones, promo codes, platform settings and waitlist sign-ups.

Sessions, cache, queued jobs, sign-in codes and API tokens are left empty. The dump is plain SQL and starts with `DROP TABLE IF EXISTS`, so importing it again resets the database. To regenerate it after changing migrations or seeders:

```bash
php artisan migrate:fresh --seed && database/dump.sh
```

## Admin control panel

| Area | What you can do |
| --- | --- |
| Dashboard | Fares and commission, trips today, drivers online, a 14-day trip chart, and every work queue in one list |
| SOS alerts | See open alerts first, with the caller's phone, location and trip; acknowledge, add notes, resolve |
| Riders | Search, view trips, bookings, payments and emergency contacts; suspend or reinstate; add wallet credit |
| Drivers | Review applications; approve, suspend or reject with a reason; set the tier; approve vehicles and choose their ride types; record cash commission received |
| Documents | Queue of uploads to review, plus documents expiring within 30 days or already expired |
| Trips | Filter by status, payment or date; see the fare breakdown and timeline; cancel; refund to the card or wallet |
| Airport shuttles | Assign a driver, update the flight status and time, cancel and refund |
| Tours | Create and edit tours, itineraries, add-ons and photos; add slots across a date range; set capacity and the Cabo guide |
| Tour bookings | Check guests in, cancel with a chosen refund, hide or show reviews |
| Partners and attractions | Approve tour operators (suspending one unpublishes its tours); edit the places guide |
| Pricing and zones | Base fare, per km, per minute and minimum fare for each ride type; zone centre, radius and surge |
| Promo codes | Percent or fixed, a cap, service, first booking only, usage limit, dates |
| Payouts and transactions | Run weekly payouts, mark them processing, paid or failed; the full money ledger |
| Support | Reply to riders and drivers (who get an in-app notification), assign tickets, set priority |
| Waitlist | Sign-ups from the website; mark them invited; export CSV |
| Settings, admin users | Waiting fees, cancellation rules, cash limit, cash-out fee, exchange rates and support contacts; admin accounts |

Roles: every admin can view every page. What they can change depends on their role:

- **Operations**: drivers, documents, trips, shuttles, tours, partners, attractions and zones.
- **Support**: tickets, SOS alerts, riders and refunds.
- **Finance**: pricing, promo codes, payouts and refunds.
- **Super admin**: everything, including settings and admin users.

## API

Base URL: `/api/v1`. Send `Accept: application/json`. Responses are JSON, with `data` holding the result. Lists are paginated with Laravel's usual `current_page`, `last_page` and `total`.

Validation errors return `422`, with `message` and an `errors` object keyed by field.

Money is whole naira (`₦`). The rider app shows the rider's home currency next to prices, using `exchange_rates` from `/config`.

### Signing in

Riders and drivers sign in with a six-digit code sent to their phone (or email, for riders).

```http
POST /api/v1/rider/auth/otp      { "identifier": "+447700900123" }
POST /api/v1/rider/auth/verify   { "identifier": "+447700900123", "code": "123456" }
→ { "token": "1|…", "is_new": false, "rider": { … } }
```

Send the token on later requests as `Authorization: Bearer <token>`. Drivers use the same flow under `/driver/auth/...`. A rider token cannot call driver endpoints, and a driver token cannot call rider endpoints.

Outside production the code is always `123456` (set `CABO_DEMO_OTP` to change it), and the `otp` response includes it as `debug_code`. In production the code is random. Codes are written to the log until an SMS or email provider is connected in `app/Services/OtpService.php`.

### Public

| Method | Path | |
| --- | --- | --- |
| GET | `/config` | Exchange rates, waiting and cancellation rules, driver rules, support contacts, service areas, ride types |
| GET | `/ride-types` | |
| GET | `/tour-categories` | |
| GET | `/tours` | Filters: `category` (slug), `q`, `max_price`, `date`, `wheelchair`, `featured`, `sort=popular\|rating\|price_low\|price_high` |
| GET | `/tours/{slug}` | Includes the latest reviews |
| GET | `/tours/{slug}/slots` | The next 30 days, with `remaining` places |
| GET | `/attractions`, `/attractions/{slug}` | Filters: `category`, `area`, `q` |
| POST | `/waitlist` | `{ name, email, source }`. Used by the website. Returns `201` for a new sign-up and `200` if the email is already on the list |

To save sign-ups from the landing page, set `WAITLIST_ENDPOINT` in `website/script.js` to `https://<backend-host>/api/v1/waitlist`. CORS allows any origin on `/api/*`.

### Rider app (`/api/v1/rider`, token with the `rider` ability)

| Method | Path | |
| --- | --- | --- |
| GET, PATCH, DELETE | `/me` | Profile: name, nationality, home currency, traveller type, language, accessibility |
| GET, POST, PUT, DELETE | `/emergency-contacts[/{id}]` | Up to 5 contacts |
| GET, POST, PUT, DELETE | `/saved-places[/{id}]` | |
| POST | `/fare-estimates` | `pickup_lat/lng`, `dropoff_lat/lng`, optional `stops[]`, `promo_code`. Returns an upfront price for every ride type |
| GET, POST | `/trips` | Book a ride: the route plus `ride_type`, `pickup_address`, `dropoff_address`, `payment_method` (`card`, `wallet`, `bank_transfer` or `cash`), and optional `scheduled_at` |
| GET | `/trips/{id}` | Includes the PIN to give the driver, the driver's live location and any waiting fee |
| POST | `/trips/{id}/cancel` | Free before a driver accepts and for 2 minutes after; then a ₦500 fee |
| POST | `/trips/{id}/stops` | Add a stop; the fare is repriced |
| POST | `/trips/{id}/rating` | `rating` 1–5, optional `feedback`, `tip` |
| POST | `/trips/{id}/share` | A link family can open to follow the ride |
| POST | `/shuttles/quote` | Fixed airport prices for `direction`, `lat`, `lng`, `passengers` |
| GET, POST | `/shuttles` | Book a shuttle with the flight number and time |
| GET | `/shuttles/{id}` | |
| POST | `/shuttles/{id}/cancel` | Full refund up to 12 hours before pickup |
| GET, POST | `/tour-bookings` | Book a tour: `tour_id`, `tour_slot_id`, `guests`, `addons[]`, `include_ride`, `promo_code`, `payment_method`. Places are checked and held atomically |
| GET | `/tour-bookings/{id}` | Includes `qr_token`, used for the ticket QR code |
| POST | `/tour-bookings/{id}/cancel` | Full refund up to 24 hours before the start, 50% after that |
| POST | `/tour-bookings/{id}/review` | Only after check-in, once per booking |
| GET, POST, DELETE | `/wishlist[/{id}]` | `{ type: tour\|attraction, id }` |
| GET | `/wallet` | Balance, loyalty points, referral code |
| POST | `/wallet/top-up` | `amount`, `method` |
| GET | `/wallet/transactions` | |
| POST | `/promo-codes/validate` | `code`, `service`, optional `amount` |

### Driver app (`/api/v1/driver`, token with the `driver` ability)

| Method | Path | |
| --- | --- | --- |
| GET, PATCH | `/me` | Profile, bank details and job preferences. Includes `online_blockers` and a summary of document status |
| POST | `/application/submit` | Moves an applicant to review once the details, documents and vehicle are in |
| GET, POST | `/documents` | Upload a document: `type`, `file` (jpg, png or pdf), optional `expires_at` and `vehicle_id` |
| GET, POST | `/vehicles` | |
| POST | `/vehicles/{id}/activate` | |
| POST | `/status` | `{ online, lat, lng }`. Returns `403` with `blockers` unless the driver is approved, all required documents are approved and in date, the vehicle is approved, and cash commission owed is within the limit |
| POST | `/location` | `{ lat, lng }` while online |
| GET | `/trips/available` | Requests within 8 km that the driver's vehicle qualifies for. The rider's PIN is never sent to the driver |
| GET | `/trips/current`, `/trips`, `/trips/{id}` | |
| POST | `/trips/{id}/accept` | First driver wins; others get `409` |
| POST | `/trips/{id}/decline` | |
| POST | `/trips/{id}/arrive` | |
| POST | `/trips/{id}/start` | `{ pin }`, the 4-digit PIN from the rider |
| POST | `/trips/{id}/complete` | Charges the rider and credits the driver's earnings. Adds waiting time beyond 5 minutes at ₦50 per minute |
| POST | `/trips/{id}/collect-cash` | For cash rides; the 20% commission is added to cash owed |
| POST | `/trips/{id}/cancel` | `reason`; use `no_show` after the free waiting time |
| POST | `/trips/{id}/rating` | Rate the rider |
| GET | `/jobs/shuttles` | Assigned airport jobs, plus open jobs the driver can claim |
| POST | `/jobs/shuttles/{id}/claim` | |
| PATCH | `/jobs/shuttles/{id}` | `status`: `in_progress` or `completed` |
| GET | `/jobs/tours` | Tour slots the driver guides, with the guest list |
| POST | `/jobs/tours/check-in` | `{ qr_token }`, scanned from the rider's ticket |
| POST | `/jobs/tours/{slot}/complete` | |
| GET | `/earnings` | `period=today\|week\|month`: trips, earnings, tips, commission, per-day totals, balance, cash owed, next payout date |
| GET | `/earnings/transactions`, `/payouts` | |
| POST | `/payouts/instant` | Instant cash-out. Cash commission owed is settled first, then a 1.5% fee is taken |

### Shared (both apps, under `/rider/...` or `/driver/...`)

| Method | Path | |
| --- | --- | --- |
| POST | `/auth/logout` | |
| POST, PATCH | `/sos[/{id}]` | Raises an alert at the top of the admin panel, and returns the rider's emergency contacts and 112 |
| GET, POST | `/support/tickets` | `category`, `subject`, `message`, optional `trip_id`, `shuttle_booking_id` or `tour_booking_id` |
| GET | `/support/tickets/{id}` | |
| POST | `/support/tickets/{id}/messages` | |
| GET | `/notifications` | Includes the `unread` count |
| POST | `/notifications/{id}/read`, `/notifications/read-all` | |

## How pricing works

Each fare is calculated up front, in `app/Services/FareCalculator.php`:

1. Distance is the straight-line route through any stops, multiplied by 1.35 for Lagos roads. Time assumes an average of 22 km/h.
2. Base fare + distance × per km + minutes × per minute.
3. That is multiplied by the surge of the zone the pickup is in.
4. The result is never less than the ride type's minimum fare.
5. Then ₦300 is added per stop, and the ₦250 Lekki toll if the route crosses the toll gate.
6. Any promo discount is taken off.

Cabo keeps 20% commission and the driver gets the rest; tips go entirely to the driver. All of these numbers are editable under **Pricing & zones** and **Settings**.

## Tests

```bash
php artisan test
```

The tests use an in-memory SQLite database seeded with the sample data. They cover:

- Admin sign-in with the seeded account, every admin page loading, and role limits.
- Rider and driver sign-in with a code.
- Fare estimates, and a full ride from request to PIN to completion to rating and tip.
- Two drivers accepting the same request, cancellation fees, and cash rides.
- Tour booking capacity, promo codes and add-ons, refunds, and reviews only after check-in.
- The rules for a driver going online, and instant cash-out.
- The waitlist endpoint.

To run them against MySQL instead, set `DB_CONNECTION=mysql` and the other `DB_*` variables in the environment.

The **Backend** GitHub Actions workflow runs the tests on SQLite. It then imports `database/cabo.sql` into MySQL 8 and runs the tests again on MySQL.

## Not connected yet

These parts are recorded in the database but not yet connected to an outside service:

- **Card and bank payments.** Charges and refunds are written to the `transactions` table. Connect a payment provider (for example Paystack or Flutterwave) in `app/Services/Wallet.php` and in the wallet top-up endpoint.
- **SMS and email sign-in codes.** These are logged only; see `app/Services/OtpService.php`.
- **Push notifications.** These are stored in `app_notifications` and returned by the `/notifications` endpoint.
- **Driver document files.** These are stored on the `local` disk under `storage/app/private/documents`. The sample data has no real files, so download links say so.
