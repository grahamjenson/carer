import 'package:signals/signals_flutter.dart';

class TimerService {
  static final TimerService _singleton = TimerService._();
  factory TimerService() => _singleton;

  TimerSignal minuteSignal = TimerSignal(
      every: const Duration(minutes: 1), debugLabel: "MinuteSignal");
  TimerService._();
}
