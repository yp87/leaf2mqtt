abstract class BuilderBase {
  BuilderBase() :
    _info = <String, String>{};

  BuilderBase.withInfo(this._info);

  final Map<String, String> _info;

  String get baseTopic;

  Map<String, String> addInfo(String key, String value) {
    final Map<String, String> modifiedInfo = Map<String, String>.from(_info);
    modifiedInfo['$baseTopic/$key'] = value;
    return modifiedInfo;
  }

  Map<String, String> build() =>
    addInfo('received_status_utc', DateTime.now().toUtc().toIso8601String());
}
