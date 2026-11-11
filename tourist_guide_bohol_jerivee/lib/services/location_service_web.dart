import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

/// Asks the browser for the visitor's location. The browser only shares a
/// position after the user grants permission.
class LocationService {
  Future<DeviceLocation?> currentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) {
    final completer = Completer<DeviceLocation?>();
    Timer? timer;

    void finish(DeviceLocation? location) {
      if (completer.isCompleted) return;
      timer?.cancel();
      completer.complete(location);
    }

    timer = Timer(timeout, () => finish(null));

    try {
      web.window.navigator.geolocation.getCurrentPosition(
        ((web.GeolocationPosition position) {
          finish(DeviceLocation(
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracyMeters: position.coords.accuracy,
          ));
        }).toJS,
        ((web.GeolocationPositionError error) => finish(null)).toJS,
        web.PositionOptions(
          enableHighAccuracy: true,
          timeout: timeout.inMilliseconds,
          maximumAge: 30000,
        ),
      );
    } catch (_) {
      finish(null);
    }

    return completer.future;
  }
}
