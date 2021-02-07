abstract class VehicleInternal extends Vehicle {
  VehicleInternal(String nickname, String vin) : super(vin) {
    _lastKnownStatus['nickname'] = nickname;
    _lastKnownStatus['vin'] = vin;
  }

  Map<String, String> saveAndPrependVin(Map<String, String> newStatus) {
    _lastKnownStatus.addAll(newStatus);
    return _prependVin(newStatus);
  }

  void setLastKnownStatus(Vehicle lastknownVehicle) =>
    _lastKnownStatus.addAll(lastknownVehicle._lastKnownStatus);

  @override
  Map<String, String> getLastKnownStatus() =>
    _prependVin(_lastKnownStatus);

  Map<String, String> _prependVin(Map<String, String> status) {
    final Map<String, String> statusWithVin = <String, String>{};

    // We also keep all status without vin for the first vehicle
    // since most people only have one vehicle.
    if (isFirstVehicle()) {
      statusWithVin.addAll(status);
    }

    status.forEach((String key, String value) => statusWithVin['$vin/$key'] = value);

    return statusWithVin;
  }
}

abstract class Vehicle {
  Vehicle(this.vin);

  final String vin;

  bool isFirstVehicle();

  bool get isCharging =>
    _findValueOfKeyIn(_lastKnownStatus, 'charging') == 'true';

  String _findValueOfKeyIn(Map<String, String> status, String key) {
    return status.entries.firstWhere(
             (MapEntry<String, String> status) =>
               status.key.endsWith(key), orElse: () => null)?.value;
  }

  final Map<String, String> _lastKnownStatus = <String, String>{};
  Map<String, String> getLastKnownStatus();

  Map<String, String> getVehicleStatus() =>
    <String, String> {
      'nickname': _lastKnownStatus['nickname'],
      'vin': _lastKnownStatus['vin']
    };

  Future<Map<String, String>> fetchBatteryStatus();
  Future<void> startCharging();

  Future<Map<String, String>> fetchClimateStatus();
  Future<void> startClimate(int targetTemperatureCelsius);
  Future<void> stopClimate();
}


