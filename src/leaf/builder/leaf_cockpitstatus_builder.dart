import 'leaf_builder_base.dart';

class CockpitStatusInfoBuilder extends BuilderBase {
  CockpitStatusInfoBuilder() : super();
  CockpitStatusInfoBuilder._withInfo(Map<String, String> info) : super.withInfo(info);

  @override
  List<String> get baseTopics => <String>['cockpitStatus', 'cockpit'];

  CockpitStatusInfoBuilder withTotalMileage(dynamic latitude) =>
    _withInfo('totalMileage', latitude);

  CockpitStatusInfoBuilder _withInfo(String infoName, dynamic value) =>
      CockpitStatusInfoBuilder._withInfo(addInfo(infoName, value));
}
