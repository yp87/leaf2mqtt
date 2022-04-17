import 'package:dartnissanconnectna/dartnissanconnectna.dart';
import 'package:logging/logging.dart';

import 'builder/leaf_battery_builder.dart';
import 'builder/leaf_climate_builder.dart';
import 'builder/leaf_location_builder.dart';
import 'builder/leaf_stats_builder.dart';
import 'leaf_session.dart';
import 'leaf_vehicle.dart';

final Logger _log = Logger('NissanConnectNASessionWrapper');

class NissanConnectNASessionWrapper extends LeafSessionInternal {
  NissanConnectNASessionWrapper(
      this._countryCode, String username, String password)
      : super(username, password);

  NissanConnectSession _session;
  final String _countryCode;

  @override
  Future<void> login() async {
    _session = NissanConnectSession(debug: _log.level <= Level.FINER);
    const String fakeAndroidUserAgent =
        'Dalvik/2.1.0 (Linux; U; Android 5.1.1; Android SDK built for x86 Build/LMY48X)';
    await _session.login(
        username: username,
        password: password,
        countryCode: _countryCode,
        userAgent: fakeAndroidUserAgent);

    final List<VehicleInternal> newVehicles = _session.vehicles
        .map((NissanConnectVehicle vehicle) =>
            NissanConnectNAVehicleWrapper(vehicle))
        .toList();

    setVehicles(newVehicles);
  }
}

class NissanConnectNAVehicleWrapper extends VehicleInternal {
  NissanConnectNAVehicleWrapper(NissanConnectVehicle vehicle)
      : _session = vehicle.session,
        super(vehicle.nickname.toString(), vehicle.vin.toString());

  final NissanConnectSession _session;

  NissanConnectVehicle _getVehicle() => _session.vehicles.firstWhere(
      (NissanConnectVehicle v) => v.vin.toString() == vin,
      orElse: () => throw Exception(
          'Could not find matching vehicle: $vin number of vehicles: ${_session.vehicles.length}'));

  @override
  bool isFirstVehicle() => _session.vehicle.vin == vin;

  @override
  Future<Map<String, String>> fetchDailyStatistics(DateTime targetDate) async =>
      fetchStatistics(TimeRange.Daily,
          await _getVehicle().requestDailyStatistics(targetDate));

  @override
  Future<Map<String, String>> fetchMonthlyStatistics(
          DateTime targetDate) async =>
      fetchStatistics(TimeRange.Monthly,
          await _getVehicle().requestMonthlyStatistics(targetDate));

  Map<String, String> fetchStatistics(
          TimeRange targetTimeRange, NissanConnectStats stats) =>
      saveAndPrependVin(StatsInfoBuilder(targetTimeRange)
          .withTargetDate(stats.date)
          .withtravelTime(stats.travelTime)
          .withTravelDistanceMiles(stats.travelDistanceMiles)
          .withTravelDistanceKilometers(stats.travelDistanceKilometers)
          .withMilesPerKwh(stats.milesPerKWh)
          .withKilometersPerKwh(stats.kilometersPerKWh)
          .withKwhUsed(stats.kWhUsed)
          .withKwhPerMiles(stats.kWhPerMiles)
          .withKwhPerKilometers(stats.kWhPerKilometers)
          .withCo2ReductionKg(stats.co2ReductionKg)
          .build());

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final NissanConnectBattery battery =
        await _getVehicle().requestBatteryStatus();

    return saveAndPrependVin(BatteryInfoBuilder()
        .withChargePercentage(
            ((battery.batteryLevel * 100) / battery.batteryLevelCapacity)
                .round())
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

  @override
  Future<bool> startCharging() => _getVehicle().requestChargingStart();

  @override
  Future<Map<String, String>> fetchClimateStatus() =>
      Future<Map<String, String>>.value(saveAndPrependVin(ClimateInfoBuilder()
          .withCabinTemperatureCelsius(_getVehicle().incTemperature)
          .build()));

  @override
  Future<bool> startClimate(int targetTemperatureCelsius) =>
      _getVehicle().requestClimateControlOn(DateTime.now());

  @override
  Future<bool> stopClimate() => _getVehicle().requestClimateControlOff();

  @override
  Future<Map<String, String>> fetchLocation() async {
    final NissanConnectLocation location =
        await _getVehicle().requestLocation(DateTime.now().toUtc());
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
