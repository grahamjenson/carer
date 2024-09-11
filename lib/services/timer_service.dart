import 'package:carer/utils/env.dart';
import 'package:carer/utils/futures.dart';
import 'package:signals/signals_flutter.dart';

class TimerService {
  static final TimerService _singleton = TimerService._();
  factory TimerService() => _singleton;

  late Signal secondSignal;
  late Signal fiveSecondSignal;
  late Signal tenSecondSignal;
  late Signal fifteenSecondSignal;
  late Signal minuteSignal;

  TimerService._() {
    if (Env.isTest) {
      // Dont create timers in tests. These can be manually triggered if needed
      minuteSignal = ASignal(0, debugLabel: "minute");
      secondSignal = ASignal(0, debugLabel: "second");
      fiveSecondSignal = ASignal(0, debugLabel: "fiveSeconds");
      tenSecondSignal = ASignal(0, debugLabel: "tenSecond");
      fifteenSecondSignal = ASignal(0, debugLabel: "fifteenSecond");
    } else {
      minuteSignal = ATimerSignal(every: const Duration(minutes: 1), debugLabel: "minute");
      secondSignal = ATimerSignal(every: const Duration(seconds: 1), debugLabel: "second");
      fiveSecondSignal = ATimerSignal(every: const Duration(seconds: 5), debugLabel: "fiveSeconds");
      tenSecondSignal = ATimerSignal(every: const Duration(seconds: 10), debugLabel: "tenSecond");
      fifteenSecondSignal = ATimerSignal(every: const Duration(seconds: 15), debugLabel: "fifteenSecond");
    }
  }
}
