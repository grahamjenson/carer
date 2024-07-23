import 'package:carer/utils/env.dart';
import 'package:signals/signals_flutter.dart';

class TimerService {
  static final TimerService _singleton = TimerService._();
  factory TimerService() => _singleton;

  late Signal secondSignal;
  late Signal tenSecondSignal;
  late Signal fifteenSecondSignal;
  late Signal minuteSignal;

  TimerService._() {
    if (Env.isTest) {
      // Dont create timers in tests. These can be manually triggered if needed
      minuteSignal = Signal(0, debugLabel: "MinuteSignal");
      secondSignal = Signal(0, debugLabel: "SecondsSignal");
      fifteenSecondSignal = Signal(0, debugLabel: "fifteenSecondSignal");
      tenSecondSignal = Signal(0, debugLabel: "tenSecondSignal");
    } else {
      minuteSignal = TimerSignal(every: const Duration(minutes: 1), debugLabel: "MinuteSignal");
      secondSignal = TimerSignal(every: const Duration(seconds: 1), debugLabel: "SecondsSignal");
      fifteenSecondSignal = TimerSignal(every: const Duration(seconds: 15), debugLabel: "fifteenSecondSignal");
      tenSecondSignal = TimerSignal(every: const Duration(seconds: 10), debugLabel: "tenSecondSignal");
    }
  }
}
