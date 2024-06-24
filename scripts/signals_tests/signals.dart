import 'package:signals/signals.dart';

Signal<int?> a = Signal(null);

void main() {
  a.value = 3;
  effect(() {
    print("hsdgiudsgihu ${a.value}");
  });

  a.value = 1;
}
