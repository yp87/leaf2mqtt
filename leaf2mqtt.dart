import 'package:dartnissanconnect/dartnissanconnect.dart';
import 'package:intl/intl.dart';
import 'package:args/args.dart';
import 'dart:convert';
import 'dart:io';

ArgResults argResults;

void main(List<String> arguments) {

  var parser = ArgParser();
  parser.addOption('username');
  parser.addOption('password');
  parser.addOption('mqtthost');
  parser.addOption('mqtttopic');
  parser.addOption('mqttuser');
  parser.addOption('mqttpass');
  var results = parser.parse(arguments);

  NissanConnectSession session = new NissanConnectSession(debug: false);

  var host = results['mqtthost'];
  var topic = results['mqtttopic'];
  var mosuser = results['mqttuser'];
  var mospass = results['mqttpass'];
  var mosopt = '-r -h ${host}';
  var retdict = {};
  var batdict = {};
  var clmdict = {};
  var sttdict = {};

  if (mosuser != null) {
    mosopt = mosopt + ' -u "${mosuser}"';
  }

  if (mospass != null) {
    mosopt = mosopt + ' -P "${mospass}"';
  }

  session
      .login(username: results['username'], password: results['password'])
      .then((vehicle) {

    vehicle.requestBatteryStatusRefresh();
    vehicle.requestClimateControlStatusRefresh();
    var vin = vehicle.vin;

    print('#!/bin/bash');
    print('echo "${vin}" > vin.txt');

    vehicle.requestMonthlyStatistics(month: DateTime.now()).then((stats) {
      sttdict['tripsNumber'] = stats.tripsNumber;
      sttdict['milesperkWh'] = stats.milesPerKWh;
      sttdict['kWhconsumed'] = stats.kWhUsed;
      sttdict['kWhregen'] = stats.kWhGained;
      sttdict['distance'] = stats.travelDistanceMiles;
      sttdict['avspeed'] = stats.travelSpeedAverageMph;
      sttdict['traveltime'] = stats.travelTime.toString();
      sttdict.forEach((k, v) => print('mosquitto_pub ${mosopt} -t "${topic}/${vin}/${k}" -m "${v}"'));
    })
    .catchError((e) {
        String ts = DateTime.now().toIso8601String();
        String en = e.toString().split(":")[0];
        print('mosquitto_pub ${mosopt} -t "${topic}/${vin}/errortime" -m "${ts}"');
        print('mosquitto_pub ${mosopt} -t "${topic}/${vin}/error" -m "${en}"');
    });

    vehicle.requestBatteryStatus().then((battery) {
      batdict['battpct'] = battery.batteryPercentage;
      batdict['connected'] = battery.isConnected;
      batdict['charging'] = battery.isCharging;
      batdict['GOM'] = battery.cruisingRangeAcOnMiles;
      batdict['time3kW'] = battery.timeToFullNormal;
      batdict['time6kW'] = battery.timeToFullFast;
      batdict.forEach((k, v) => print('mosquitto_pub ${mosopt} -t "${topic}/${vin}/${k}" -m "${v}"'));
    });

    vehicle.requestClimateControlStatus().then((climate) {
      clmdict['cabintemp'] = climate.cabinTemperature;
      clmdict['hvacrunning'] = climate.isRunning;
      clmdict.forEach((k, v) => print('mosquitto_pub ${mosopt} -t "${topic}/${vin}/${k}" -m "${v}"'));
    });

    retdict['nickname'] = vehicle.nickname;
    retdict['modelname'] = vehicle.modelName;
    retdict['vin'] = vehicle.vin;
    retdict['updated'] = DateTime.now().toIso8601String();
    
    retdict.forEach((k, v) => print('mosquitto_pub ${mosopt} -t "${topic}/${vin}/${k}" -m "${v}"'));

  });
}
