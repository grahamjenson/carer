import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/models/sql/db_model.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';

class Profile extends DateRangeDBModel {
  final int dia;
  final String name;
  final String units;
  final String timezone;

  final String source;

  final int percent;

  final List<int> carbratio;
  final List<int> sens;
  final List<double> basal;
  final List<int> lowTarget;
  final List<int> highTarget;

  Profile({
    super.id,
    required this.name,
    required super.eid,
    // Date Range
    required super.startDate,
    required super.duration,
    // Profile
    required this.dia,
    required this.units,
    required this.timezone,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.lowTarget,
    required this.highTarget,
    required this.source,
    required this.percent,
  });

  get isTempProfile => duration != 0;

  @override
  bool operator ==(Object other) {
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  DateTime get endDate {
    // A Profile with duration 0 means indefinite
    if (duration == 0) {
      return startDate.add(const Duration(days: 35600));
    } else {
      return startDate.add(Duration(seconds: duration));
    }
  }

  static Future<Profile?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await SQLToProfile().query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<List<Profile>> after(DateTime date) async {
    return SQLToProfile().query(conditions: {
      "end >= ?": date.millisecondsSinceEpoch,
    });
  }

  static Future<Profile?> profile() async {
    return SQLToProfile().query(limit: 1, name: "lastProfile").then((value) => value.firstOrNull);
  }

  static ASignal<Profile?> currentProfile = ASignal<Profile?>(null, debugLabel: 'currentProfile');

  static Future<void> setupSQLSignals() async {
    await signalAssign(
      currentProfile,
      () => atTime(clock.now()),
      debugLabel: 'fetchCurrentProfile',
      dependencies: [SQLToProfile().writeSignal, TimerService().fifteenSecondSignal],
    );
  }

  @override
  String toString() {
    return "Profile($eid, $startDate, $duration, $name, $percent%)";
  }
}

const crKeys = [
  "cr0",
  "cr1",
  "cr2",
  "cr3",
  "cr4",
  "cr5",
  "cr6",
  "cr7",
  "cr8",
  "cr9",
  "cr10",
  "cr11",
  "cr12",
  "cr13",
  "cr14",
  "cr15",
  "cr16",
  "cr17",
  "cr18",
  "cr19",
  "cr20",
  "cr21",
  "cr22",
  "cr23"
];

const isfKeys = [
  "isf0",
  "isf1",
  "isf2",
  "isf3",
  "isf4",
  "isf5",
  "isf6",
  "isf7",
  "isf8",
  "isf9",
  "isf10",
  "isf11",
  "isf12",
  "isf13",
  "isf14",
  "isf15",
  "isf16",
  "isf17",
  "isf18",
  "isf19",
  "isf20",
  "isf21",
  "isf22",
  "isf23"
];

const basalKeys = [
  "basal0",
  "basal1",
  "basal2",
  "basal3",
  "basal4",
  "basal5",
  "basal6",
  "basal7",
  "basal8",
  "basal9",
  "basal10",
  "basal11",
  "basal12",
  "basal13",
  "basal14",
  "basal15",
  "basal16",
  "basal17",
  "basal18",
  "basal19",
  "basal20",
  "basal21",
  "basal22",
  "basal23"
];

const lowTargetKeys = [
  "tlow0",
  "tlow1",
  "tlow2",
  "tlow3",
  "tlow4",
  "tlow5",
  "tlow6",
  "tlow7",
  "tlow8",
  "tlow9",
  "tlow10",
  "tlow11",
  "tlow12",
  "tlow13",
  "tlow14",
  "tlow15",
  "tlow16",
  "tlow17",
  "tlow18",
  "tlow19",
  "tlow20",
  "tlow21",
  "tlow22",
  "tlow23"
];

const highTargetKeys = [
  "thigh0",
  "thigh1",
  "thigh2",
  "thigh3",
  "thigh4",
  "thigh5",
  "thigh6",
  "thigh7",
  "thigh8",
  "thigh9",
  "thigh10",
  "thigh11",
  "thigh12",
  "thigh13",
  "thigh14",
  "thigh15",
  "thigh16",
  "thigh17",
  "thigh18",
  "thigh19",
  "thigh20",
  "thigh21",
  "thigh22",
  "thigh23"
];
