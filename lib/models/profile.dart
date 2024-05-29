import 'package:carer/sql/carer_db.dart';

class Profile {
  final DateTime date;
  final int dia;
  final String units;
  final String timezone;

  final List<int> carbratio;
  final List<int> sens;
  final List<double> basal;
  final List<int> targetLow;
  final List<int> targetHigh;

  Profile({
    required this.date,
    required this.dia,
    required this.units,
    required this.timezone,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.targetLow,
    required this.targetHigh,
  });

  factory Profile.fromMap(Map<String, Object?> map) {
    assert(map["dia"] != null);
    assert(map["units"] != null);
    assert(map["timezone"] != null);

    List<int> carbratio = CarerDB.crKeys.map((key) => map[key] as int).toList();
    List<int> sens = CarerDB.isfKeys.map((key) => map[key] as int).toList();
    List<double> basal =
        CarerDB.basalKeys.map((key) => map[key] as double).toList();
    List<int> targetLow =
        CarerDB.targetLowKeys.map((key) => map[key] as int).toList();
    List<int> targetHigh =
        CarerDB.targetHighKeys.map((key) => map[key] as int).toList();

    return Profile(
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      dia: map["dia"] as int,
      units: map["units"] as String,
      timezone: map["timezone"] as String,
      carbratio: carbratio,
      sens: sens,
      basal: basal,
      targetLow: targetLow,
      targetHigh: targetHigh,
    );
  }

  static Future<Profile?> profile() async {
    var db = await CarerDB.instance;
    var profile = await db.profile();
    if (profile == null) {
      return null;
    }
    return Profile.fromMap(profile);
  }

  static Future<int> createOrUpdate(Profile model) async {
    Map<String, Object> map = {
      "dia": model.dia,
      "units": model.units,
      "timezone": model.timezone,
    };
    model.carbratio.asMap().forEach((index, value) {
      map[CarerDB.crKeys[index]] = value;
    });
    model.sens.asMap().forEach((index, value) {
      map[CarerDB.isfKeys[index]] = value;
    });
    model.basal.asMap().forEach((index, value) {
      map[CarerDB.basalKeys[index]] = value;
    });
    model.targetLow.asMap().forEach((index, value) {
      map[CarerDB.targetLowKeys[index]] = value;
    });
    model.targetHigh.asMap().forEach((index, value) {
      map[CarerDB.targetHighKeys[index]] = value;
    });

    var db = await CarerDB.instance;
    return db.createOrUpdateProfile(map);
  }
}
