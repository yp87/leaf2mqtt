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

    final List<VehicleInternal> vehicles = _session.vehicles.map((NissanConnectVehicle vehicle) =>
      NissanConnectVehicleWrapper(vehicle)).toList();

    setVehicles(vehicles);
  }
}

class NissanConnectVehicleWrapper extends VehicleInternal {
  NissanConnectVehicleWrapper(NissanConnectVehicle vehicle) :
    _session = vehicle.session,
    super(vehicle.nickname.toString(), vehicle.vin.toString());

  final NissanConnectSession _session;

  NissanConnectVehicle _getVehicle() =>
    _session.vehicles.firstWhere((NissanConnectVehicle v) => v.vin == vin);

  @override
  bool isFirstVehicle() => _session.vehicle.vin == vin;

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final NissanConnectBattery battery = await _getVehicle().requestBatteryStatus();

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
    _getVehicle().requestChargingStart();

  @override
  Future<Map<String, String>> fetchClimateStatus() async {
    final NissanConnectVehicle vehicle = _getVehicle();

    await vehicle.requestClimateControlStatusRefresh();
    final NissanConnectHVAC hvac = await vehicle.requestClimateControlStatus();

    return saveAndPrependVin(ClimateInfoBuilder()
            .withCabinTemperatureCelsius(hvac.cabinTemperature)
            .withHvacRunningStatus(hvac.isRunning)
            .build());
  }

  @override
  Future<void> startClimate(int targetTemperatureCelsius) =>
    _getVehicle().requestClimateControlOn(
      DateTime.now().add(const Duration(seconds: 5)),
      targetTemperatureCelsius);

  @override
  Future<void> stopClimate() =>
    _getVehicle().requestClimateControlOff();
}
