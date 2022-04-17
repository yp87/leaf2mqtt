import 'leaf_builder_base.dart';

class LocationInfoBuilder extends BuilderBase {
  LocationInfoBuilder() : super();
  LocationInfoBuilder._withInfo(Map<String, String> info)
      : super.withInfo(info);

  @override
  String get baseTopic => 'location';

  LocationInfoBuilder withLatitude(dynamic latitude) =>
      _withInfo('latitude', latitude);

  LocationInfoBuilder withLongitude(dynamic longitude) =>
      _withInfo('longitude', longitude);

  LocationInfoBuilder _withInfo(String infoName, dynamic value) =>
      LocationInfoBuilder._withInfo(addInfo(infoName, value));
}
