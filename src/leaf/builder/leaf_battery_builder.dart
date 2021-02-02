import 'package:dartnissanconnect/dartnissanconnect.dart';

import 'leaf_builder_base.dart';

class BatteryInfoBuilder extends BuilderBase {
  BatteryInfoBuilder() : super();
  BatteryInfoBuilder._withInfo(Map<String, String> info) : super.withInfo(info);

  @override
  String get baseTopic => 'battery';

  BatteryInfoBuilder withChargePercentage(int chargePercentage) =>
    _withInfo('percentage', chargePercentage);

  BatteryInfoBuilder withChargingStatus(bool charging) =>
    _withInfo('charging', charging);

  BatteryInfoBuilder withConnectedStatus(bool connected) =>
    _withInfo('connected', connected);

  BatteryInfoBuilder withCapacity(double capacity) =>
    _withInfo('capacity', capacity);

  BatteryInfoBuilder withCruisingRangeAcOffKm(String cruisingRangeAcOffKm) =>
    _withInfo('cruisingRangeAcOffKm', removeUnitFromValue(cruisingRangeAcOffKm));

  BatteryInfoBuilder withCruisingRangeAcOffMiles(String cruisingRangeAcOffMiles) =>
    _withInfo('cruisingRangeAcOffMiles', removeUnitFromValue(cruisingRangeAcOffMiles));

  BatteryInfoBuilder withCruisingRangeAcOnKm(String cruisingRangeAcOnKm) =>
    _withInfo('cruisingRangeAcOnKm', removeUnitFromValue(cruisingRangeAcOnKm));

  BatteryInfoBuilder withCruisingRangeAcOnMiles(String cruisingRangeAcOnMiles) =>
    _withInfo('cruisingRangeAcOnMiles', removeUnitFromValue(cruisingRangeAcOnMiles));

  BatteryInfoBuilder withLastUpdatedDateTime(DateTime lastUpdatedDateTime) =>
    _withInfo('lastUpdatedDateTimeUtc', lastUpdatedDateTime.toUtc().toIso8601String());

  BatteryInfoBuilder withTimeToFullL2(Duration timeToFullL2) =>
    _addIfNotZero('timeToFullL2InMinutes', timeToFullL2);

  BatteryInfoBuilder withTimeToFullL2_6kw(Duration timeToFullL2_6kw) =>
    _addIfNotZero('timeToFullL2_6kwInMinutes', timeToFullL2_6kw);

  BatteryInfoBuilder withTimeToFullTrickle(Duration timeToFullTrickle) =>
    _addIfNotZero('timeToFullTrickleInMinutes', timeToFullTrickle);

  BatteryInfoBuilder withChargingSpeed(ChargingSpeed chargingSpeed) =>
    _withInfo('chargingSpeed', chargingSpeed);

  BatteryInfoBuilder _addIfNotZero(String infoName, Duration value) =>
    value.inMinutes == 0 ? this : _withInfo(infoName, value.inMinutes);

  BatteryInfoBuilder _withInfo(String infoName, dynamic value) =>
      BatteryInfoBuilder._withInfo(addInfo(infoName, value));
}
