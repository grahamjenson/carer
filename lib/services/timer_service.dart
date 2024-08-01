import 'package:carer/utils/env.dart';
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
      minuteSignal = Signal(0, debugLabel: "minute");
      secondSignal = Signal(0, debugLabel: "second");
      fiveSecondSignal = Signal(0, debugLabel: "fiveSeconds");
      tenSecondSignal = Signal(0, debugLabel: "tenSecond");
      fifteenSecondSignal = Signal(0, debugLabel: "fifteenSecond");
    } else {
      minuteSignal = TimerSignal(every: const Duration(minutes: 1), debugLabel: "minute");
      secondSignal = TimerSignal(every: const Duration(seconds: 1), debugLabel: "second");
      fiveSecondSignal = TimerSignal(every: const Duration(seconds: 5), debugLabel: "fiveSeconds");
      tenSecondSignal = TimerSignal(every: const Duration(seconds: 10), debugLabel: "tenSecond");
      fifteenSecondSignal = TimerSignal(every: const Duration(seconds: 15), debugLabel: "fifteenSecond");
    }
  }
}
