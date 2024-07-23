import 'package:carer/utils/logs.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessAlert {
  // singleton
  static final BrightnessAlert _singleton = BrightnessAlert._();
  factory BrightnessAlert() => _singleton;
  BrightnessAlert._();

  bool torched = false;

  Future<void> start() async {
    alog("BRIGHTNESS: SET 1.0");
    try {
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      throw 'BRIGHTNESS Alarm: Failed to set brightness';
    }
  }

  Future<void> stop() async {
    alog("BRIGHTNESS: RESET");
    ScreenBrightness().resetScreenBrightness();
  }
}
