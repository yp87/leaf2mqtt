import 'package:dartnissanconnectna/dartnissanconnectna.dart';

import 'builder/leaf_battery_builder.dart';
import 'leaf_session.dart';
import 'leaf_vehicle.dart';

class NissanConnectNASessionWrapper extends LeafSessionInternal {
  NissanConnectNASessionWrapper(this._countryCode);

  final NissanConnectSession _session = NissanConnectSession();
  final String _countryCode;

  @override
  Future<void> login(String username, String password) async {
    await _session.login(username: username, password: password, countryCode: _countryCode);

    int vehicleNumber = 0;
    final List<VehicleInternal> vehicles = _session.vehicles.map((NissanConnectVehicle vehicle) =>
      NissanConnectNAVehicleWrapper(vehicle, vehicleNumber++)).toList();

    setVehicles(vehicles);
  }
}

class NissanConnectNAVehicleWrapper extends VehicleInternal {
  NissanConnectNAVehicleWrapper(this._vehicle, int vehicleNumber) :
    super(_vehicle.nickname.toString(), _vehicle.vin.toString(), vehicleNumber == 0);

  final NissanConnectVehicle _vehicle;

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final NissanConnectBattery battery = await _vehicle.requestBatteryStatus();

    return lastBatteryStatus = prependVin(BatteryInfoBuilder()
           .withChargePercentage(((battery.batteryLevel * 100) / battery.batteryLevelCapacity).round())
           .withConnectedStatus(battery.isConnected)
           .withChargingStatus(battery.isCharging)
           .withCapacity(battery.batteryLevelCapacity.toDouble())
           .withCruisingRangeAcOffKm(battery.cruisingRangeAcOffKm)
           .withCruisingRangeAcOffMiles(battery.cruisingRangeAcOffMiles)
           .withCruisingRangeAcOnKm(battery.cruisingRangeAcOnKm)
           .withCruisingRangeAcOnMiles(battery.cruisingRangeAcOnMiles)
           .withLastUpdatedDateTime(battery.dateTime)
           .withTimeToFullL2(battery.timeToFullL2)
           .withTimeToFullL2_6kw(battery.timeToFullL2_6kw)
           .withTimeToFullTrickle(battery.timeToFullTrickle)
           .build());
  }
}
