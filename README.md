# fluttercabo
Mono repo for Cabo app

## Structure

| Folder | Component |
| --- | --- |
| [`rider-app/`](rider-app) | Cabo Rider app (iOS and Android) |
| [`driver-app/`](driver-app) | Cabo Driver app (Android first, then iOS) |
| [`partner-portal/`](partner-portal) | Partner portal (web) for tour operators, guides, attractions and hotels |
| [`website/`](website) | Marketing website |
| [`backend/`](backend) | Laravel and MySQL: admin control panel and the rider and driver APIs, with a SQL dump of the sample data ([setup](backend/README.md)) |
| [`screenshots/`](screenshots) | Screenshots of the apps: [`driver/`](screenshots/driver) and [`rider/`](screenshots/rider) |

## CI

GitHub Actions tests the Flutter apps and builds release APKs, and tests the backend. The workflows live in `.github/workflows/`:

- `rider-app.yml` runs on any push that changes `rider-app/`
- `driver-app.yml` runs on any push that changes `driver-app/`
- `flutter-android.yml` is the shared job both of them call
- `backend.yml` runs on any push that changes `backend/`: the Laravel tests on SQLite, then an import of `backend/database/cabo.sql` into MySQL 8 and the tests again on MySQL

To run one by hand, go to **Actions**, pick a workflow and click **Run workflow**. For the apps, download the APK when it finishes from the run's **Artifacts** section.
