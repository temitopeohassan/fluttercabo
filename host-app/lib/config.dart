/// Set with `--dart-define=SCREENSHOT_MODE=true` when capturing screenshots.
/// Turns off timers and looping animations so every screen renders the same
/// way each time.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

/// Base URL of the Cabo backend API. The app does not call it yet; screens use
/// sample data. Override with `--dart-define=API_BASE_URL=...` to point a
/// build at another server, such as a local `php artisan serve`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://controlpanel.caboapp.online/api/v1',
);
