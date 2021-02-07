import 'package:dartnissanconnectna/dartnissanconnectna.dart';
import 'package:logging/logging.dart';

import 'builder/leaf_battery_builder.dart';
import 'leaf_session.dart';
import 'leaf_vehicle.dart';

final Logger _log = Logger('NissanConnectNASessionWrapper');

class NissanConnectNASessionWrapper extends LeafSessionInternal {
  NissanConnectNASessionWrapper(this._countryCode, String username, String password)
    : super(username, password);

  NissanConnectSession _session;
  final String _countryCode;

  @override
  Future<void> login() async {
    _session = NissanConnectSession(debug: _log.level <= Level.FINER);
    await _session.login(username: username, password: password, countryCode: _countryCode);

    final List<VehicleInternal> newVehicles = _session.vehicles.map((NissanConnectVehicle vehicle) =>
      NissanConnectNAVehicleWrapper(vehicle)).toList();

    setVehicles(newVehicles);
  }
}

class NissanConnectNAVehicleWrapper extends VehicleInternal {
  NissanConnectNAVehicleWrapper(NissanConnectVehicle vehicle) :
    _session = vehicle.session,
    super(vehicle.nickname.toString(), vehicle.vin.toString());

  final NissanConnectSession _session;

  NissanConnectVehicle _getVehicle() =>
    _session.vehicles.firstWhere((NissanConnectVehicle v) => v.vin.toString() == vin,
      orElse: () => throw Exception('Could not find matching vehicle: $vin number of vehicles: ${_session.vehicles.length}'));

  @override
  bool isFirstVehicle() => _session.vehicle.vin == vin;

  @override
  Future<Map<String, String>> fetchBatteryStatus() async {
    final NissanConnectBattery battery = await _getVehicle().requestBatteryStatus();

    return saveAndPrependVin(BatteryInfoBuilder()
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

  @override
  Future<void> startCharging() =>
    _getVehicle().requestChargingStart();

  @override
  Future<Map<String, String>> fetchClimateStatus() =>
    Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<void> startClimate(int targetTemperatureCelsius) =>
    _getVehicle().requestClimateControlOn(DateTime.now().add(const Duration(seconds: 5)));

  @override
  Future<void> stopClimate() =>
    _getVehicle().requestClimateControlOff();
}
