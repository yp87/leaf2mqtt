import 'package:logging/logging.dart';

import 'leaf_vehicle.dart';
import 'nissan_connect_na_wrapper.dart';
import 'nissan_connect_wrapper.dart';

final Logger _log = Logger('LeafSession');

enum LeafType {
  newerThanMay2019,
  olderCanada,
  olderUsa,
  // olderEurope,
  // olderAustralia,
  // olderJapan,
}

class LeafSessionFactory {
  static LeafSession createLeafSession(LeafType leafType, String username, String password) {
    switch (leafType) {
      case LeafType.newerThanMay2019:
        return NissanConnectSessionWrapper(username, password);
        break;

      case LeafType.olderCanada:
        return NissanConnectNASessionWrapper('CA', username, password);
        break;

      case LeafType.olderUsa:
        return NissanConnectNASessionWrapper('US', username, password);
        break;

      default:
        throw ArgumentError.value(leafType, 'leafType', 'this LeafType is not supported yet.');

      // Need to have a working blowfish encryption.
      /*case LeafType.olderEurope:
        return CarwingsWrapper(CarwingsRegion.Europe);
        break;

      case LeafType.olderJapan:
        return CarwingsWrapper(CarwingsRegion.Japan);
        break;

      case LeafType.olderAustralia:
        return CarwingsWrapper(CarwingsRegion.Australia);
        break;*/
    }
  }
}

abstract class LeafSessionInternal extends LeafSession {
  LeafSessionInternal(this.username, this.password);

  final String username;
  final String password;

  List<VehicleInternal> _lastKnownVehicles = <VehicleInternal>[];

  @override
  List<Vehicle> get vehicles => _lastKnownVehicles;

  void setVehicles(List<VehicleInternal> newVehicles) {
    // keep the last states
    for (final VehicleInternal lastKnownVehicle in _lastKnownVehicles) {
      final VehicleInternal matchingVehicle =
        newVehicles.firstWhere((VehicleInternal vehicle) => vehicle.vin == lastKnownVehicle.vin, orElse: () => null);
      matchingVehicle?.setLastKnownStatus(lastKnownVehicle);
    }

    _lastKnownVehicles = newVehicles;
  }

  @override
  Map<String, String> getAllLastKnownStatus() =>
      _lastKnownVehicles.fold(<String, String>{},
      (Map<String, String> allLastKnownStatus, VehicleInternal vehicle) {
        allLastKnownStatus.addAll(vehicle.getLastKnownStatus());
        return allLastKnownStatus;
      } );
}

typedef ExecutableVehicleActionHandler<T> = Future<T> Function(Vehicle vehicle);
typedef SyncExecutableVehicleActionHandler<T> = T Function(Vehicle vehicle);
abstract class LeafSession {

  List<Vehicle> get vehicles;

   Vehicle _getVehicle(String vin) =>
    vehicles.firstWhere((Vehicle vehicle) => vehicle.vin == vin,
                        orElse: () => throw Exception('Vehicle $vin not found.'));

  Future<void> login();

  Map<String, String> getAllLastKnownStatus();

  T executeSync<T>(SyncExecutableVehicleActionHandler<T> executable, String vin) {
      try {
        return executable(_getVehicle(vin));
      } catch (e, stackTrace) {
        _logException(e, stackTrace);
      }

      return null;
  }

  Future<T> executeWithRetry<T>(ExecutableVehicleActionHandler<T> executable, String vin) async {
    int attempts = 0;
    while (attempts < 2) {
      try {
        return await _execute(executable, vin);
      } catch (e, stackTrace) {
        _logException(e, stackTrace);
      }

      _log.finer('Force a login before retrying failed execution.');
      await login();
      ++attempts;
    }

    return null;
  }

  Future<T> _execute<T>(ExecutableVehicleActionHandler<T> executable, String vin) {
    _log.finest('Executing');
    return executable(_getVehicle(vin));
  }

  void _logException(dynamic e, StackTrace stackTrace) {
    _log.fine(e);
    _log.finer(stackTrace);
  }
}

