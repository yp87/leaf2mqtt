import 'package:dartnissanconnect/dartnissanconnect.dart';
import 'package:intl/intl.dart';
import 'package:args/args.dart';
import 'dart:io';

ArgResults argResults;

void main(List<String> arguments) {

  var parser = ArgParser();
  parser.addOption('username');
  parser.addOption('password');
  parser.addOption('operation');
  var results = parser.parse(arguments);

  NissanConnectSession session = new NissanConnectSession(debug: false);

  session
    .login(username: results['username'], password: results['password'])
    .then((vehicle) {

    if (results['operation'] == 'on') {
        vehicle.requestChargingStart();
    }
    else {
        vehicle.requestChargingStop();
    }
  });
}
