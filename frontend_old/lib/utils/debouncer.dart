import 'dart:async';
import 'dart:ui';

class Debouncer {
  /// How long to wait after the last call before running.
  final Duration delay;

  Timer? timer;

  Debouncer({required this.delay});

  /// Call this instead of your function. It will schedule [action]
  /// to run after [delay], cancelling any previous pending call.
  void run(VoidCallback action) {
    timer?.cancel(); // Cancel any existing timer
    timer = Timer(delay, action); // Schedule a new one
  }

  /// Should be called (e.g., in dispose()) to clean up resources.
  void dispose() {
    timer?.cancel();
  }
}
