import 'package:dartnissanconnect/dartnissanconnect.dart';
import 'package:dartnissanconnect/src/nissanconnect_hvac.dart';

import 'builder/leaf_battery_builder.dart';
import 'builder/leaf_climate_builder.dart';
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
      NissanConnectVehicleWrapper(vehicle, vehicleNumber++)).toList();

    setVehicles(vehicles);
  }
}

class NissanConnectVehicleWrapper extends VehicleInternal {
  NissanConnectVehicleWrapper(this._vehicle, int vehicleNumber) :
    super(_vehicle.nickname.toString(), _vehicle.vin.toString(), vehicleNumber == 0);

  final NissanConnectVehicle _vehicle;

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final NissanConnectBattery battery = await _vehicle.requestBatteryStatus();

    final int percentage =
      double.tryParse(battery.batteryPercentage.replaceFirst('%', ''))?.round();

    return saveAndPrependVin(BatteryInfoBuilder()
           .withChargePercentage(percentage ?? -1)
           .withConnectedStatus(battery.isConnected)
           .withChargingStatus(battery.isCharging)
           .withCruisingRangeAcOffKm(battery.cruisingRangeAcOffKm)
           .withCruisingRangeAcOffMiles(battery.cruisingRangeAcOffMiles)
           .withCruisingRangeAcOnKm(battery.cruisingRangeAcOnKm)
           .withCruisingRangeAcOnMiles(battery.cruisingRangeAcOnMiles)
           .withLastUpdatedDateTime(battery.dateTime)
           .withTimeToFullL2(battery.timeToFullNormal)
           .withTimeToFullL2_6kw(battery.timeToFullFast)
           .withTimeToFullTrickle(battery.timeToFullSlow)
           .withChargingSpeed(battery.chargingSpeed.toString())
           .build());
  }

  @override
  Future<void> startCharging() =>
    _vehicle.requestChargingStart();

  @override
  Future<Map<String, String>> fetchClimateStatus() async {
    await _vehicle.requestClimateControlStatusRefresh();
    final NissanConnectHVAC hvac = await _vehicle.requestClimateControlStatus();

    return saveAndPrependVin(ClimateInfoBuilder()
            .withCabinTemperatureCelsius(hvac.cabinTemperature)
            .withHvacRunningStatus(hvac.isRunning)
            .build());
  }

  @override
  Future<void> startClimate(int targetTemperatureCelsius) =>
    _vehicle.requestClimateControlOn(DateTime.now().add(const Duration(seconds: 5)), targetTemperatureCelsius);

  @override
  Future<void> stopClimate() =>
    _vehicle.requestClimateControlOff();
}
