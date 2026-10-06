/// Set with `--dart-define=SCREENSHOT_MODE=true` when capturing screenshots.
/// Turns off timers and looping animations so every screen renders the same
/// way each time.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
