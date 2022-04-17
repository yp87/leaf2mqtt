import 'package:dartcarwings/dartcarwings.dart';

import 'builder/leaf_battery_builder.dart';
import 'builder/leaf_climate_builder.dart';
import 'builder/leaf_location_builder.dart';
import 'builder/leaf_stats_builder.dart';
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
    await _session.login(
        username: username, password: password, region: _region);

    final List<VehicleInternal> newVehicles = _session.vehicles
        .map((CarwingsVehicle vehicle) => CarwingsVehicleWrapper(vehicle))
        .toList();

    setVehicles(newVehicles);
  }
}

class CarwingsVehicleWrapper extends VehicleInternal {
  CarwingsVehicleWrapper(CarwingsVehicle vehicle)
      : _session = vehicle.session,
        super(vehicle.nickname.toString(), vehicle.vin.toString());

  final CarwingsSession _session;

  CarwingsVehicle _getVehicle() => _session.vehicles.firstWhere(
      (CarwingsVehicle v) => v.vin.toString() == vin,
      orElse: () => throw Exception(
          'Could not find matching vehicle: $vin number of vehicles: ${_session.vehicles.length}'));

  @override
  bool isFirstVehicle() => _session.vehicle.vin == vin;

  @override
  Future<Map<String, String>> fetchDailyStatistics(DateTime targetDate) =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<Map<String, String>> fetchMonthlyStatistics(
      DateTime targetDate) async {
    final CarwingsStatsMonthly stats =
        await _getVehicle().requestStatisticsMonthly(targetDate);

    return saveAndPrependVin(StatsInfoBuilder(TimeRange.Monthly)
        .withTargetDate(stats.dateTime)
        .withTripsNumber(int.tryParse(stats.totalNumberOfTrips))
        .withCo2ReductionKg(stats.totalCO2Reduction)
        .build());
  }

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final CarwingsBattery battery =
        await _getVehicle().requestBatteryStatusLatest();

    return saveAndPrependVin(BatteryInfoBuilder()
        .withChargePercentage(
            ((battery.batteryLevel * 100) / battery.batteryLevelCapacity)
                .round())
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
  Future<bool> startCharging() async {
    await _getVehicle().requestChargingStart(DateTime.now());
    return true;
  }

  @override
  Future<Map<String, String>> fetchClimateStatus() async {
    final CarwingsCabinTemperature cabinTemperature =
        await _getVehicle().requestCabinTemperature();
    final CarwingsHVAC hvac = await _getVehicle().requestHVACStatus();

    return saveAndPrependVin(ClimateInfoBuilder()
        .withCabinTemperatureCelsius(cabinTemperature.temperature)
        .withHvacRunningStatus(hvac.isRunning)
        .build());
  }

  @override
  Future<bool> startClimate(int targetTemperatureCelsius) async {
    await _getVehicle().requestClimateControlOn();
    return true;
  }

  @override
  Future<bool> stopClimate() async {
    await _getVehicle().requestClimateControlOff();
    return true;
  }

  @override
  Future<Map<String, String>> fetchLocation() async {
    final CarwingsLocation location = await _getVehicle().requestLocation();
    return saveAndPrependVin(LocationInfoBuilder()
        .withLatitude(location.latitude)
        .withLongitude(location.longitude)
        .build());
  }

  // Note: This is only a dummy method. It returns an empty map.
  @override
  Future<Map<String, String>> fetchCockpitStatus() async {
    return Future<Map<String, String>>.value(<String, String>{});
  }
}
