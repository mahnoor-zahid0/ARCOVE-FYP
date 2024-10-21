import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryInfo {
  final Battery _battery = Battery();

  Future<void> getBatteryLevel() async {
    int batteryLevel = await _battery.batteryLevel;
    print('Battery level: $batteryLevel%');
  }
}
