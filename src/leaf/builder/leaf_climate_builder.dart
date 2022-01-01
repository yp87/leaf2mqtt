import 'leaf_builder_base.dart';

class ClimateInfoBuilder extends BuilderBase {
  ClimateInfoBuilder() : super();
  ClimateInfoBuilder._withInfo(Map<String, String> info) : super.withInfo(info);

  @override
  String get baseTopic => 'climate';

  ClimateInfoBuilder withCabinTemperatureCelsius(double cabinTemperatureCelsius) =>
    _withInfo('cabinTemperatureC', cabinTemperatureCelsius)
    ._withInfo('cabinTemperatureF', (cabinTemperatureCelsius * 9 / 5) + 32);

  ClimateInfoBuilder withHvacRunningStatus(bool isRunning) =>
    _withInfo('RunningStatus', isRunning)
    ._withInfo('runningStatus', isRunning);

  ClimateInfoBuilder _withInfo(String infoName, dynamic value) =>
      ClimateInfoBuilder._withInfo(addInfo(infoName, value));
}
