import 'package:dartnissanconnect/dartnissanconnect.dart';
import 'package:intl/intl.dart';
import 'package:args/args.dart';
import 'dart:io';

ArgResults argResults;

void main(List<String> arguments) {

  var parser = ArgParser();
  parser.addOption('username');
  parser.addOption('password');
  parser.addOption('temperature', defaultsTo: '20');
  var results = parser.parse(arguments);

  NissanConnectSession session = new NissanConnectSession(debug: false);

  var temperature = 0;

  if (results['temperature'] != 'off') {
    temperature = int.parse(results['temperature']);
  }

  session
    .login(username: results['username'], password: results['password'])
    .then((vehicle) {

    vehicle.requestClimateControlStatusRefresh()
      .then((_) {
        vehicle.requestClimateControlStatus()
          .then((_) {});
      });

    if (temperature == 0) {
      stdout.write('requesting climate off...');
      vehicle.requestClimateControlOff()
        .then((_) {
          stdout.write('success.\n');
        }).catchError((error) {
          stdout.write('failed.\n');
        });
    }
    else {
      stdout.write('requesting climate at ${temperature}°C...');
      vehicle.requestClimateControlOn(DateTime.now(), temperature.toInt())
        .then((_) {
          stdout.write('success.\n');
        }).catchError((error) {
          stdout.write('failed.\n');
        });
    }

    vehicle.requestClimateControlStatusRefresh()
      .then((_) {
        vehicle.requestClimateControlStatus()
          .then((_) {});
      });
  });
}
