import 'package:dartcarwings/dartcarwings.dart';

import 'builder/leaf_battery_builder.dart';
import 'builder/leaf_climate_builder.dart';
import 'leaf_session.dart';
import 'leaf_vehicle.dart';

class CarwingsWrapper extends LeafSessionInternal {
  CarwingsWrapper(this._region, String username, String password)
    : super(username, password);

  final CarwingsRegion _region;

  CarwingsSession _session;

  @override
  Future<void> login() async {
    _session = CarwingsSession();
    await _session.login(username: username, password: password, region: _region,
                         blowfishEncryptCallback: blowFishEncrypt);

    final List<VehicleInternal> newVehicles = _session.vehicles.map((CarwingsVehicle vehicle) =>
      CarwingsVehicleWrapper(vehicle)).toList();

    setVehicles(newVehicles);
  }

  Future<String> blowFishEncrypt(String keyString, String password) async {
    // Use starflut to do it in python? need to have flutter sdk...
    // Maybe do it in js? would need nodejs.
    throw UnimplementedError('Cannot connect to CarWings Api: Blowfish encryption is not implemented yet.');
  }
}

class CarwingsVehicleWrapper extends VehicleInternal {
  CarwingsVehicleWrapper(CarwingsVehicle vehicle) :
    _session = vehicle.session,
    super(vehicle.nickname.toString(), vehicle.vin.toString());

  final CarwingsSession _session;

  CarwingsVehicle _getVehicle() =>
    _session.vehicles.firstWhere((CarwingsVehicle v) => v.vin.toString() == vin,
      orElse: () => throw Exception('Could not find matching vehicle: $vin number of vehicles: ${_session.vehicles.length}'));

  @override
  bool isFirstVehicle() => _session.vehicle.vin == vin;

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final CarwingsBattery battery = await _getVehicle().requestBatteryStatusLatest();

    return saveAndPrependVin(BatteryInfoBuilder()
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

  @override
  Future<void> startCharging() =>
    _getVehicle().requestChargingStart(DateTime.now().add(const Duration(seconds: 5)));

  @override
  Future<Map<String, String>> fetchClimateStatus() async {
    final CarwingsCabinTemperature cabinTemperature = await _getVehicle().requestCabinTemperatureLatest();
    final CarwingsHVAC hvac = await _getVehicle().requestHVACStatus();

    return saveAndPrependVin(ClimateInfoBuilder()
            .withCabinTemperatureCelsius(cabinTemperature.temperature)
            .withHvacRunningStatus(hvac.isRunning)
            .build());
  }

  @override
  Future<void> startClimate(int targetTemperatureCelsius) =>
    _getVehicle().requestClimateControlOn();

  @override
  Future<void> stopClimate() =>
    _getVehicle().requestClimateControlOff();
}
