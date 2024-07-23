import 'package:carer/utils/logs.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessAlert {
  // singleton
  static final BrightnessAlert _singleton = BrightnessAlert._();
  factory BrightnessAlert() => _singleton;
  BrightnessAlert._();

  double? originalBrightness;
  bool torched = false;

  Future<void> start() async {
    originalBrightness = await currentBrightness();
    alog("ORIGINAL BRIGHTNESS: $originalBrightness");
    await setBrightness(1.0);
  }

  Future<void> stop() async {
    if (originalBrightness != null) {
      await setBrightness(originalBrightness!);
      originalBrightness = null;
    }
  }

  Future<double> currentBrightness() async {
    try {
      return await ScreenBrightness().current;
    } catch (e) {
      throw 'BRIGHTNESS Alarm: Failed to get current brightness';
    }
  }

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {
      throw 'BRIGHTNESS Alarm: Failed to set brightness';
    }
  }
}
