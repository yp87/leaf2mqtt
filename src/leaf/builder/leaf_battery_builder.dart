import 'leaf_builder_base.dart';

class BatteryInfoBuilder extends BuilderBase {
  BatteryInfoBuilder() : super();
  BatteryInfoBuilder._withInfo(Map<String, String> info) : super.withInfo(info);

  @override
  String get baseTopic => 'battery';

  BatteryInfoBuilder withChargePercentage(int chargePercentage) =>
    BatteryInfoBuilder._withInfo(addInfo('percentage', chargePercentage.toString()));

  BatteryInfoBuilder withChargingStatus(bool charging) =>
    BatteryInfoBuilder._withInfo(addInfo('charging', charging.toString()));

  BatteryInfoBuilder withConnectedStatus(bool connected) =>
    BatteryInfoBuilder._withInfo(addInfo('connected', connected.toString()));
}
