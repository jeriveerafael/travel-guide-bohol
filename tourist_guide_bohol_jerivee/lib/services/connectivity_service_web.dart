import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Reports the browser's online status and notifies listeners when it changes.
class ConnectivityService {
  ConnectivityService() {
    _online = web.window.navigator.onLine;
    _onlineHandler = ((web.Event event) => _update(true)).toJS;
    _offlineHandler = ((web.Event event) => _update(false)).toJS;
    web.window.ononline = _onlineHandler;
    web.window.onoffline = _offlineHandler;
  }

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  late final JSFunction _onlineHandler;
  late final JSFunction _offlineHandler;
  bool _online = true;

  bool get isOnline => _online;

  Stream<bool> get changes => _controller.stream;

  void _update(bool value) {
    if (_online == value) return;
    _online = value;
    if (!_controller.isClosed) _controller.add(value);
  }

  void dispose() {
    web.window.ononline = null;
    web.window.onoffline = null;
    _controller.close();
  }
}
