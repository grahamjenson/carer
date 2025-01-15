import 'package:carer/utils/logs.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessAlert {
  // singleton
  static final BrightnessAlert _singleton = BrightnessAlert._();
  factory BrightnessAlert() => _singleton;
  BrightnessAlert._();

  bool started = false;

  Future<void> start() async {
    if (started) {
      return;
    }
    try {
      started = true;
      alog("BRIGHTNESS: SET 1.0");

      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      throw 'BRIGHTNESS Alarm: Failed to set brightness';
    }
  }

  Future<void> stop() async {
    if (started) {
      started = false;
      alog("BRIGHTNESS: RESET");

      ScreenBrightness().resetScreenBrightness();
    }
  }
}
