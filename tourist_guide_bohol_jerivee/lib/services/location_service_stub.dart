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

/// Location is only available in the web build.
class LocationService {
  Future<DeviceLocation?> currentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) async =>
      null;
}
