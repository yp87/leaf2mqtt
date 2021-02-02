abstract class VehicleInternal extends Vehicle {
  VehicleInternal(String nickname, String vin, this._isFirstVehicle) : super(vin) {
    final Map<String, String> vehicleStatus = <String, String>{};
    vehicleStatus['nickname'] = nickname;
    vehicleStatus['vin'] = vin;
    lastVehicleStatus = prependVin(vehicleStatus);
  }

  final bool _isFirstVehicle;

  void setLastKnownStatus(Vehicle lastKnownVehicle) {
    // Skip lastVehicleStatus since it is set in constructor

    lastBatteryStatus = lastKnownVehicle.lastBatteryStatus;
  }

  Map<String, String> getLastKnownStatus() {
    final Map<String, String> lastKnownStates = <String, String>{};
    lastKnownStates.addAll(lastVehicleStatus);
    lastKnownStates.addAll(lastBatteryStatus);
    return lastKnownStates;
  }

  Map<String, String> prependVin(Map<String, String> status)
  {
    final Map<String, String> statusWithVin = <String, String>{};

    // We also keep all status without vin for the first vehicle
    // since most people only have one vehicle.
    if (_isFirstVehicle) {
      statusWithVin.addAll(status);
    }

    status.forEach((String key, String value) => statusWithVin['$vin/$key'] = value);

    return statusWithVin;
  }
}

abstract class Vehicle {
  Vehicle(this.vin);

  final String vin;

  bool get isCharging =>
    findValueOfKeyIn(lastBatteryStatus, 'charging') == 'true';

  String findValueOfKeyIn(Map<String, String> status, String key) {
    return status.entries.firstWhere(
             (MapEntry<String, String> status) =>
               status.key.endsWith(key), orElse: () => null)?.value;
  }

  Map<String, String> lastVehicleStatus = <String, String>{};

  Map<String, String> lastBatteryStatus = <String, String>{};
  Future<void> fetchBatteryStatus();

  Future<void> startCharging();
}


