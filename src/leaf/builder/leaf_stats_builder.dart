import 'leaf_builder_base.dart';

enum TimeRange {
  Daily,
  Monthly,
}

class StatsInfoBuilder extends BuilderBase {
  StatsInfoBuilder(this._targetTimeRange) : super();
  StatsInfoBuilder._withInfo(this._targetTimeRange, Map<String, String> info) : super.withInfo(info);

  final TimeRange _targetTimeRange;

  @override
  String get baseTopic => 'stats/${_targetTimeRange.toString().split('.').last.toLowerCase()}';

  StatsInfoBuilder withTargetDate(DateTime targetDate) =>
    _withInfo('targetDate', targetDate);

  StatsInfoBuilder withtravelTime(Duration travelTime) =>
    _withInfo('travelTimeHours', travelTime.inHours);

  StatsInfoBuilder withTravelDistanceMiles(String travelDistanceMiles) =>
    _withSpecifiedUnitInfo('travelDistanceMiles', travelDistanceMiles);

  StatsInfoBuilder withTravelDistanceKilometers(String travelDistanceKilometers) =>
    _withSpecifiedUnitInfo('travelDistanceKilometers', travelDistanceKilometers);

  StatsInfoBuilder withMilesPerKwh(String milesPerKwh) =>
    _withSpecifiedUnitInfo('milesPerKwh', milesPerKwh);

  StatsInfoBuilder withKilometersPerKwh(String kilometersPerKwh) =>
    _withSpecifiedUnitInfo('kilometersPerKwh', kilometersPerKwh);

  StatsInfoBuilder withKwhUsed(String kwhUsed) =>
    _withSpecifiedUnitInfo('kwhUsed', kwhUsed);

  StatsInfoBuilder withKwhPerMiles(String kwhPerMiles) =>
    _withSpecifiedUnitInfo('kwhPerMiles', kwhPerMiles);

  StatsInfoBuilder withKwhPerKilometers(String kwhPerKilometers) =>
    _withSpecifiedUnitInfo('kwhPerKilometers', kwhPerKilometers);

  StatsInfoBuilder withCo2ReductionKg(String co2ReductionKg) =>
    _withSpecifiedUnitInfo('co2ReductionKg', co2ReductionKg);

  StatsInfoBuilder withTripsNumber(int tripsNumber) =>
    _withInfo('tripsNumber', tripsNumber);

  StatsInfoBuilder withKwhGained(String kWhGained) =>
    _withSpecifiedUnitInfo('kWhGained', kWhGained);

  StatsInfoBuilder _withSpecifiedUnitInfo(String infoName, String valueWithUnit) =>
    _withInfo(infoName, valueWithUnit.split(' ').first);

  StatsInfoBuilder _withInfo(String infoName, dynamic value) =>
      StatsInfoBuilder._withInfo(_targetTimeRange, addInfo(infoName, value));
}
