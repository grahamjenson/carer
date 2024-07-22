import 'package:carer/utils/logs.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:torch_light/torch_light.dart';

class BrightnessAlarm {
  double? originalBrightness;
  bool torched = false;

  Future<void> start() async {
    await enableTorch();
    originalBrightness = await currentBrightness();
    alog("ORIGINAL BRIGHTNESS: $originalBrightness");
    await setBrightness(1.0);
  }

  Future<void> stop() async {
    disableTorch();

    if (originalBrightness != null) {
      await setBrightness(originalBrightness!);
      originalBrightness = null;
    }
  }

  Future<void> enableTorch() async {
    try {
      await TorchLight.enableTorch();
    } on Exception catch (_) {
      alog("BRIGHTNESS Alarm: Failed to enable Torch");
    }
  }

  Future<void> disableTorch() async {
    try {
      await TorchLight.disableTorch();
    } on Exception catch (_) {
      alog("BRIGHTNESS Alarm: Failed to Disable Torch");
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
