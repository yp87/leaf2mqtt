import 'leaf_vehicle.dart';
import 'nissan_connect_na_wrapper.dart';
import 'nissan_connect_wrapper.dart';

enum LeafType {
  newerThanMay2019,
  olderCanada,
  olderUsa,
  olderOther
}

class LeafSessionFactory {
  static LeafSession createLeafSession(LeafType leafType) {
    switch (leafType) {
      case LeafType.olderCanada:
        return NissanConnectNASessionWrapper('CA');
        break;

      case LeafType.olderUsa:
        return NissanConnectNASessionWrapper('US');
        break;

      case LeafType.newerThanMay2019:
        return NissanConnectSessionWrapper();
        break;

      default:
        throw ArgumentError.value(leafType, 'leafType', 'this LeafType is not supported yet.');
    }
  }
}

abstract class LeafSessionInternal extends LeafSession {
  List<VehicleInternal> _lastKnownVehicles = <VehicleInternal>[];

  @override
  List<Vehicle> get vehicles => _lastKnownVehicles;

  void setVehicles(List<VehicleInternal> vehicles) {
    // keep the last states
    for (final VehicleInternal lastKnownVehicle in _lastKnownVehicles) {
      final VehicleInternal matchingVehicle =
        vehicles.firstWhere((VehicleInternal vehicle) => vehicle.vin == lastKnownVehicle.vin, orElse: () => null);
      matchingVehicle?.setLastKnownStatus(lastKnownVehicle);
    }

    _lastKnownVehicles = vehicles;
  }

  @override
  Map<String, String> getAllLastKnownStatus() {
    final Map<String, String> allLastknownStatus = <String, String>{};
    final List<VehicleInternal> vehicles = _lastKnownVehicles;

    for (final VehicleInternal vehicle in vehicles) {
      allLastknownStatus.addAll(vehicle.getLastKnownStatus());
    }

    return allLastknownStatus;
  }
}

abstract class LeafSession {
  List<Vehicle> get vehicles;

  Future<void> login(String userName, String password);
  Map<String, String> getAllLastKnownStatus();
}

