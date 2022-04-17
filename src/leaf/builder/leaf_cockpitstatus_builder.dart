import 'leaf_builder_base.dart';

class CockpitStatusInfoBuilder extends BuilderBase {
  CockpitStatusInfoBuilder() : super();
  CockpitStatusInfoBuilder._withInfo(Map<String, String> info)
      : super.withInfo(info);

  @override
  String get baseTopic => 'cockpit';

  CockpitStatusInfoBuilder withTotalMileage(dynamic mileage) =>
      _withInfo('totalMileageKM', mileage)._withInfo(
          'totalMileageMi', (mileage * 0.6213712).toStringAsFixed(0));

  CockpitStatusInfoBuilder _withInfo(String infoName, dynamic value) =>
      CockpitStatusInfoBuilder._withInfo(addInfo(infoName, value));
}
