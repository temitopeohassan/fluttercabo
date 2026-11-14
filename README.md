# fluttercabo
Mono repo for Cabo app

## Structure

| Folder | Component |
| --- | --- |
| [`guest-app/`](guest-app) | Cabo Guest app (iOS and Android), for visitors booking rides, shuttles and tours. Runs on the live backend ([setup](guest-app/README.md)) |
| [`host-app/`](host-app) | Cabo Host app (Android first, then iOS), for drivers and driver-guides. Runs on the live backend ([setup](host-app/README.md)) |
| [`partner-portal/`](partner-portal) | React and Vite partner portal for tour operators, guides, attractions and hotels, running on JSON demo data for now ([setup](partner-portal/README.md)) |
| [`website/`](website) | Marketing website |
| [`backend/`](backend) | Laravel and MySQL: admin control panel and the APIs the Guest and Host apps use, deployed at https://controlpanel.caboapp.online, with a SQL dump of the sample data ([setup](backend/README.md)) |
| [`screenshots/`](screenshots) | Screenshots of the apps: [`host/`](screenshots/host) and [`guest/`](screenshots/guest) |

The Guest app was called the Rider app and the Host app the Driver app. The backend keeps `/rider` and `/driver` in its API paths and table names.

## CI

GitHub Actions tests the Flutter apps and builds release APKs, and tests the backend. The workflows live in `.github/workflows/`:

- `guest-app.yml` runs on any push that changes `guest-app/`
- `host-app.yml` runs on any push that changes `host-app/`
- `flutter-android.yml` is the shared job both of them call
- `partner-portal.yml` runs on any push that changes `partner-portal/`: lint, tests and a production build, uploaded as an artifact
- `backend.yml` runs on any push that changes `backend/`: the Laravel tests on SQLite, then an import of `backend/database/cabo.sql` into MySQL 8 and the tests again on MySQL

To run one by hand, go to **Actions**, pick a workflow and click **Run workflow**. For the apps, download the APK when it finishes from the run's **Artifacts** section.
