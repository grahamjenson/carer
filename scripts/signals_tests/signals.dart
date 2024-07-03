import 'package:carer/utils/futures.dart';
import 'package:signals/signals.dart';

Signal<Set<int>> a = Signal({});

void main() {
  a.value = {1, 2, 3};
  aeffect(() {
    print("hsdgiudsgihu ${a.value}");
  });

  a.value = {1, 2, 3};
  a.value = {1, 2, 3};
  a.value = {1, 2, 3};
}
