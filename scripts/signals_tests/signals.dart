import 'package:carer/utils/futures.dart';

ASignal<Set<int>> a = ASignal({}, debugLabel: "a");

void main() {
  a.value = {1, 2, 3};
  aeffect(
    () {
      print("hsdgiudsgihu ${a.value}");
    },
    debugLabel: "",
  );

  a.value = {1, 2, 3};
  a.value = {1, 2, 3};
  a.value = {1, 2, 3};
}
