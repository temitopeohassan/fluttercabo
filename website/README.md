# Cabo Website

Public marketing website for Cabo. Booking is mobile only.

## Landing page

`index.html` is a single static landing page. It has no build step and no dependencies; open it in a browser or serve the folder from any static host.

```sh
cd website
python3 -m http.server 8000   # then open http://localhost:8000
```

| File | What's there |
| --- | --- |
| `index.html` | The page: hero, features, destinations, app screenshots, safety, waitlist form, footer |
| `styles.css` | Brand colours, layout and the responsive breakpoints (960px and 560px) |
| `script.js` | Waitlist form validation and submission |
| `assets/images/` | The Cabo logo, favicon, Lagos photos and rider app screenshots (see below) |
| `assets/fonts/` | Poppins, self-hosted as WOFF2 (SIL Open Font License) |

### Navigation

- **Join waitlist** scrolls to the waitlist form.
- **Are you a driver?** opens a blank new window (`about:blank`). Replace that `href` in `index.html` (it appears in the header and the footer) once the driver sign-up page exists.

### Waitlist form

The form collects a **name** and an **email address**. It checks both fields before submitting and shows a confirmation message.

Submissions are **not stored yet**. Set `WAITLIST_ENDPOINT` at the top of `script.js` to a URL that accepts a JSON `POST` of:

```json
{ "name": "Tunde Bakare", "email": "tunde@example.com", "source": "website" }
```

That can be a Cabo backend endpoint or a form service such as Formspree. Until it is set, sign-ups are only logged to the browser console. The form also has a hidden honeypot field that quietly drops bot submissions.

### Logo and images

- **Logo:** `logo-wordmark-dark.png` (header) and `logo-lockup-light.png` (footer, with the Ride • Tour • Travel tagline) are cut out of the Cabo logo artwork supplied by the team. `logo-wordmark-light.png` and `logo-lockup-dark.png` are the other colour variants. `favicon.png` and `apple-touch-icon.png` are the ring-and-pin "o". The source artwork is a small JPEG, so replace these with exports from the original vector logo when it is available.
- **Hero:** `lekki-bridge-sunset.jpg`, the Lekki-Ikoyi Link Bridge at sunset.
- **App screenshots:** `app-*.jpg` come from `screenshots/rider/`. Regenerate them from there if the app screens change.

### Photos

The destination photos are the ones supplied for the rider app (see `rider-app/assets/photos/CREDITS.md`). Confirm the right to use each one before the site goes live; the night skyline photo carries an "f27" watermark.
