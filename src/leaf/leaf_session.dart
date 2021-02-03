import 'leaf_vehicle.dart';
import 'nissan_connect_na_wrapper.dart';
import 'nissan_connect_wrapper.dart';

enum LeafType {
  newerThanMay2019,
  olderCanada,
  olderUsa,
  // olderEurope,
  // olderAustralia,
  // olderJapan,
}

class LeafSessionFactory {
  static LeafSession createLeafSession(LeafType leafType) {
    switch (leafType) {
      case LeafType.newerThanMay2019:
        return NissanConnectSessionWrapper();
        break;

      case LeafType.olderCanada:
        return NissanConnectNASessionWrapper('CA');
        break;

      case LeafType.olderUsa:
        return NissanConnectNASessionWrapper('US');
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
  List<VehicleInternal> _lastKnownVehicles = <VehicleInternal>[];

  @override
  List<Vehicle> get vehicles => _lastKnownVehicles;

  void setVehicles(List<VehicleInternal> vehicles) {
    // keep the last states
    for (final VehicleInternal lastKnownVehicle in _lastKnownVehicles) {
      final VehicleInternal matchingVehicle =
        vehicles.firstWhere((VehicleInternal vehicle) => vehicle.vin == lastKnownVehicle.vin, orElse: () => null);
      matchingVehicle?.setLastKnownState(lastKnownVehicle);
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

