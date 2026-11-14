import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Makes the [AppState] available to every screen.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// The app state. The calling widget rebuilds when it changes.
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// The app state, without subscribing to changes. Use in callbacks.
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? CaboColors.red : CaboColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Message to show for any error thrown by an API or location call.
String errorText(Object error) => error is ApiException || error is Exception && error is! FormatException
    ? '$error'.replaceFirst('Exception: ', '')
    : 'Something went wrong. Please try again.';

/// Loads data when first shown, with a spinner, and an error message with a
/// retry button if it fails. [builder] gets the data and a reload callback.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder, this.padding = const EdgeInsets.all(32)});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final EdgeInsets padding;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  T? _data;
  bool _loaded = false;
  Object? _error;
  bool _loading = true;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final run = ++_run;
    if (mounted) setState(() => _loading = true);
    try {
      final data = await widget.load();
      if (!mounted || run != _run) return;
      setState(() {
        _data = data;
        _loaded = true;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || run != _run) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The data itself may be null, for screens with nothing to show yet.
    if (_loaded) return widget.builder(context, _data as T, _load);
    final Widget body = _loading
        ? Padding(
            padding: widget.padding,
            child: const Center(child: CircularProgressIndicator(color: CaboColors.yellow)),
          )
        : ErrorNotice(errorText(_error!), onRetry: _load, padding: widget.padding);
    // A loader used as a whole screen supplies its own page while it waits.
    if (Scaffold.maybeOf(context) != null) return body;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.of(context).maybePop())
            : null,
      ),
      body: Center(child: body),
    );
  }
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key, this.onRetry, this.padding = const EdgeInsets.all(32)});
  final String message;
  final VoidCallback? onRetry;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: CaboColors.muted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: CaboText.body),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            CaboButton('Try again', style: CaboButtonStyle.secondary, height: 44, expand: false, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

class EmptyNotice extends StatelessWidget {
  const EmptyNotice(this.message, {super.key, this.icon = Icons.inbox_rounded, this.action, this.onAction});
  final String message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 40, color: CaboColors.muted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: CaboText.muted.copyWith(fontSize: 14)),
          if (action != null) ...[const SizedBox(height: 14), CaboButton(action!, height: 44, expand: false, onPressed: onAction)],
        ],
      ),
    );
  }
}

/// A [CaboButton] for an action that calls the API: shows progress, blocks
/// double taps and reports errors in a snackbar.
class ActionButton extends StatefulWidget {
  const ActionButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.style = CaboButtonStyle.primary,
    this.height = 56,
    this.expand = true,
    this.enabled = true,
    this.busyLabel,
  });

  final String label;
  final Future<void> Function() onPressed;
  final IconData? icon;
  final CaboButtonStyle style;
  final double height;
  final bool expand;
  final bool enabled;
  final String? busyLabel;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CaboButton(
      _busy ? (widget.busyLabel ?? 'Please wait…') : widget.label,
      icon: _busy ? null : widget.icon,
      style: widget.style,
      height: widget.height,
      expand: widget.expand,
      onPressed: widget.enabled && !_busy ? _run : null,
    );
  }
}

/// Runs an API action from a tap handler and shows any error.
Future<bool> runAction(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) showMessage(context, errorText(e), error: true);
    return false;
  }
}

/// Opens turn-by-turn directions to a point in the phone's maps app.
Future<void> openNavigation(BuildContext context, double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showMessage(context, 'Could not open a maps app on this phone.', error: true);
}

/// Opens the phone dialler.
Future<void> callNumber(BuildContext context, String number) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!ok && context.mounted) showMessage(context, 'Could not open the phone app. Dial $number.', error: true);
}
