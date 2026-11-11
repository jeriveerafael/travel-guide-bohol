import 'dart:async';

/// Fallback connectivity service for non-web platforms.
class ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool get isOnline => true;

  Stream<bool> get changes => _controller.stream;

  void dispose() {
    _controller.close();
  }
}
