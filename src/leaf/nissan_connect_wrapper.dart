import 'package:dartnissanconnect/dartnissanconnect.dart';

import 'builder/leaf_battery_builder.dart';
import 'leaf_session.dart';
import 'leaf_vehicle.dart';

class NissanConnectSessionWrapper extends LeafSessionInternal {
  NissanConnectSessionWrapper();

  final NissanConnectSession _session = NissanConnectSession();

  @override
  Future<void> login(String username, String password) async {
    await _session.login(username: username, password: password);

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

    final int percentage =
      double.tryParse(battery.batteryPercentage.replaceFirst('%', ''))?.round();

    return lastBatteryStatus = prependVin(BatteryInfoBuilder()
           .withChargePercentage(percentage ?? -1)
           .withConnectedStatus(battery.isConnected)
           .withChargingStatus(battery.isCharging)
           .build());
  }
}
