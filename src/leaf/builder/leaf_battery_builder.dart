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
      _withInfo(
          'cruisingRangeAcOffKm', removeUnitFromValue(cruisingRangeAcOffKm));

  BatteryInfoBuilder withCruisingRangeAcOffMiles(
          String cruisingRangeAcOffMiles) =>
      _withInfo('cruisingRangeAcOffMiles',
          removeUnitFromValue(cruisingRangeAcOffMiles));

  BatteryInfoBuilder withCruisingRangeAcOnKm(String cruisingRangeAcOnKm) =>
      _withInfo(
          'cruisingRangeAcOnKm', removeUnitFromValue(cruisingRangeAcOnKm));

  BatteryInfoBuilder withCruisingRangeAcOnMiles(
          String cruisingRangeAcOnMiles) =>
      _withInfo('cruisingRangeAcOnMiles',
          removeUnitFromValue(cruisingRangeAcOnMiles));

  BatteryInfoBuilder withLastUpdatedDateTime(DateTime lastUpdatedDateTime) =>
      _withInfo('lastUpdatedDateTimeUtc',
          lastUpdatedDateTime.toUtc().toIso8601String());

  BatteryInfoBuilder withTimeToFullL2(Duration timeToFullL2) =>
      _withInfo('timeToFullL2InMinutes', timeToFullL2.inMinutes);

  BatteryInfoBuilder withTimeToFullL2_6kw(Duration timeToFullL2_6kw) =>
      _withInfo('timeToFullL2_6kwInMinutes', timeToFullL2_6kw.inMinutes);

  BatteryInfoBuilder withTimeToFullTrickle(Duration timeToFullTrickle) =>
      _withInfo('timeToFullTrickleInMinutes', timeToFullTrickle.inMinutes);

  BatteryInfoBuilder withChargingSpeed(String chargingSpeed) =>
      _withInfo('chargingSpeed', chargingSpeed);

  BatteryInfoBuilder _withInfo(String infoName, dynamic value) =>
      BatteryInfoBuilder._withInfo(addInfo(infoName, value));
}
