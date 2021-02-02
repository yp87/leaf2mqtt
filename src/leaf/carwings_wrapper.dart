import 'package:dartcarwings/dartcarwings.dart';

import 'builder/leaf_battery_builder.dart';
import 'leaf_session.dart';
import 'leaf_vehicle.dart';

class CarwingsWrapper extends LeafSessionInternal {
  CarwingsWrapper(this._region);

  final CarwingsRegion _region;

  final CarwingsSession _session = CarwingsSession();

  @override
  Future<void> login(String username, String password) async {
    await _session.login(username: username, password: password, region: _region,
                         blowfishEncryptCallback: blowFishEncrypt);

    int vehicleNumber = 0;
    final List<VehicleInternal> vehicles = _session.vehicles.map((CarwingsVehicle vehicle) =>
      CarwingsVehicleWrapper(vehicle, vehicleNumber++)).toList();

    setVehicles(vehicles);
  }

  Future<String> blowFishEncrypt(String keyString, String password) async {
    // Use starflut to do it in python? need to have flutter sdk...
    // Maybe do it in js? would need nodejs.
    throw UnimplementedError('Cannot connect to CarWings Api: Blowfish encryption is not implemented yet.');
  }
}

class CarwingsVehicleWrapper extends VehicleInternal {
  CarwingsVehicleWrapper(this._vehicle, int vehicleNumber) :
    super(_vehicle.nickname.toString(), _vehicle.vin.toString(), vehicleNumber == 0);

  final CarwingsVehicle _vehicle;

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final CarwingsBattery battery = await _vehicle.requestBatteryStatusLatest();

    return lastBatteryStatus = prependVin(BatteryInfoBuilder()
           .withChargePercentage(((battery.batteryLevel * 100) / battery.batteryLevelCapacity).round())
           .withConnectedStatus(battery.isConnected)
           .withChargingStatus(battery.isCharging)
           .withCapacity(battery.batteryLevelCapacity)
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
