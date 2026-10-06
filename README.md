# fluttercabo
Mono repo for Cabo app

## Structure

| Folder | Component |
| --- | --- |
| [`rider-app/`](rider-app) | Cabo Rider app (iOS and Android) |
| [`driver-app/`](driver-app) | Cabo Driver app (Android first, then iOS) |
| [`partner-portal/`](partner-portal) | Partner portal (web) for tour operators, guides, attractions and hotels |
| [`website/`](website) | Marketing website |
| [`backend/`](backend) | Backend services and APIs |
| [`screenshots/`](screenshots) | Screenshots of the apps, e.g. [`screenshots/driver/`](screenshots/driver) |

## CI

GitHub Actions tests the Flutter apps and builds release APKs. The workflows live in `.github/workflows/`:

- `rider-app.yml` runs on any push that changes `rider-app/`
- `driver-app.yml` runs on any push that changes `driver-app/`
- `flutter-android.yml` is the shared job both of them call

To run one by hand, go to **Actions**, pick a workflow and click **Run workflow**. When it finishes, download the APK from the run's **Artifacts** section.
