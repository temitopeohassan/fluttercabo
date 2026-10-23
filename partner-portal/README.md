# Cabo Partner Portal

The web portal for Cabo's partners: tour operators, independent guides, attractions and hotels. It is built with React 19 and Vite, and covers every partner portal requirement in the PRD (P-01 to P-09).

For now all data, including sign-in accounts, comes from one JSON file: [`src/data/db.json`](src/data/db.json). The portal does not call the Cabo backend yet.

## Run it

You need Node 20 or later.

```bash
cd partner-portal
npm install
npm run dev        # http://localhost:5173
```

Other scripts:

| Command | |
| --- | --- |
| `npm test` | 36 Vitest tests of sign-in, the partner rules and the main screens |
| `npm run lint` | oxlint |
| `npm run build` | Production build in `dist/` |
| `npm run seed` | Regenerates `src/data/db.json` from `scripts/seed.mjs` |

The built site is a single-page app. Configure the web server to serve `index.html` for any path that is not a file, so that links such as `/bookings/bk12` work.

## Demo accounts

Every account uses the password **`password123!`**. You can also fill them in from the sign-in page.

| Email | Business | What it shows |
| --- | --- | --- |
| `adaeze@ekonaturetrails.ng` | Eko Nature Trails | Tour operator with live tours, bookings today, reviews and payouts |
| `funmi@funmiisland.ng` | Funmi Island Tours | Tour operator with a tour returned by Cabo for changes |
| `kunle@badagryroots.ng` | Badagry Roots Guides | Guide whose application is still in review |
| `ifeoma@lekkiartshub.ng` | Lekki Arts Hub | Attraction selling entry tickets |
| `bisi@lagoonhouse.ng` | The Lagoon House | Hotel using the concierge to book rides for guests |

## Features

| PRD | Feature | Where |
| --- | --- | --- |
| Sign-in | Email and password sign-in, "keep me signed in", lockout after 5 failed attempts, password reset with a 6-digit code, password change, sign out | `/login`, `/forgot-password`, Settings → Password |
| P-01 | Apply to join in four steps: business and partner type, guides, documents (CAC registration and insurance with expiry), then account and payout bank. After applying, the partner can follow their application's status and prepare draft tours | `/apply`, `/application` |
| P-02 | Create and edit tours: photos (resized in the browser, first photo is the cover), itinerary, price, group size, inclusions and exclusions, add-ons (per person or per booking), meeting point, guides, cancellation policy (flexible, moderate or strict), wheelchair access. Tours are sent for Cabo review. Changes to a live tour are reviewed while it stays bookable. Tours can be paused or deleted | `/tours`, `/tours/:id` |
| P-03 | Month calendar of time slots with booked and capacity counts. Add slots on chosen weekdays and times across a date range. Change capacity, remove empty slots, and block a date for one tour or all tours. Blocking warns first, then cancels and fully refunds that day's bookings | `/availability` |
| P-04 | Bookings with guest name, country, party size, add-ons, Cabo ride add-on and special requests. Phone numbers are masked. Partners can export a guest list (CSV), cancel a booking with a reason and a full refund, or mark a no-show. In-app notifications, plus settings for email and WhatsApp alerts | `/bookings`, `/notifications`, Settings → Alerts |
| P-05 | Check-in from a phone browser: scan the guest's QR ticket with the camera (jsQR), or type the reference. Shows a clear valid or invalid result: already used, another day, cancelled, or another partner's ticket. Today's guest list has one-tap check-in | `/check-in` |
| P-06 | Earnings after the 15% commission, the next Tuesday payout, monthly chart, payout history and a per-booking breakdown, with CSV export. Changing the payout bank needs the partner's password | `/earnings`, Settings → Bank details |
| P-07 | Reply to reviews, and edit or remove the reply. Filter by tour, unanswered or low ratings. Rating breakdown | `/reviews` |
| P-08 | Attractions list ticket types (price, daily limit, validity), pause sales, see sales by date, and admit visitors by scanning tickets | `/tickets`, `/check-in` |
| P-09 | Hotel concierge: book rides, airport pickups (with flight number) and airport drop-offs for guests. Ride estimates use the backend's fare formula and airport trips have fixed prices. Bill the hotel account or the guest. Cancel bookings, and see the monthly total billed to the hotel | `/concierge` |
| Privacy | Download all of the partner's data as JSON, and ask to close the account (Nigeria Data Protection Act 2023 and GDPR) | Settings → Privacy and data |

The menu changes with the partner. Tour operators and guides see tours, availability, bookings, check-in and reviews. Attractions see tickets, hotels see the concierge, and partners still in review see only their application, draft tours and settings.

## How the JSON data works

- `scripts/seed.mjs` writes `src/data/db.json`. The file holds partners, users, tours, slots, blocked dates, bookings, reviews, payouts, notifications, ticket types and sales, and concierge bookings, all as sample data for Lagos.
- Passwords are stored as salted PBKDF2-SHA256 hashes (100,000 iterations), never in plain text. The browser checks them with the Web Crypto API.
- Dates in the file are relative to the day it was generated. On first load the portal moves every date forward to today, so there are always guests to check in today and bookings in the coming weeks.
- Changes made in the portal are saved in the browser's `localStorage`, so they survive a reload. **Settings → Privacy and data → Reset demo data** goes back to the file.
- Every data call goes through `src/api/` (`auth.js`, `portal.js` and `store.js`). Those functions are async and return the same shapes an HTTP API would. To connect the Laravel backend later, replace their bodies with `fetch` calls; the pages do not need to change.

**This is for development only.** Because the JSON file ships to the browser, anyone can read it, password hashes included, and partners' changes stay in their own browser. Before real partners use the portal, move accounts and data to the backend.

## Not done yet

These will come with the backend:

- **Notifications:** email, WhatsApp and SMS are not actually sent. The portal records what would be sent and shows it under Notifications. The password reset code is shown on screen.
- **Uploads:** only each document's name and size are kept. Tour photos are stored in the browser.
- **Cabo review:** reviewing tours, tickets and applications happens on Cabo's side, in the admin panel. In the demo these stay "In review".
- **Accessibility and localisation:** pages have labels, focus styles, a skip link, live regions and AA-contrast colours. Amounts are formatted in naira and times in Lagos time. Text is in English only and not yet extracted for translation.
