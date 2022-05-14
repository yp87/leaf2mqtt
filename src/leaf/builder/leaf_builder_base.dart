import 'dart:convert';

abstract class BuilderBase {
  BuilderBase() :
    _info = <String, String>{};

  BuilderBase.withInfo(this._info);

  final Map<String, String> _info;

  String get baseTopic => '';

  List<String> get baseTopics => <String>[baseTopic];

  Map<String, String> addInfo(String key, dynamic value) {
    final Map<String, String> modifiedInfo = Map<String, String>.from(_info);
    modifiedInfo[key] = value.toString();
    return modifiedInfo;
  }

  String removeUnitFromValue(String valueWithUnit) =>
    valueWithUnit.split(' ')[0];

  Map<String, String> build() {
    final Map<String, String> info =
      addInfo('lastReceivedDateTimeUtc', DateTime.now().toUtc().toIso8601String());
    info['json'] = json.encode(info);

    return Map<String, String>.fromEntries(
      baseTopics.map((String baseTopic) =>
        info.map((String key, String value) =>
          MapEntry<String, String>('$baseTopic/$key', value)))
      .expand((Map<String, String> element) => element.entries));
  }
}
