import 'package:carer/models/model.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:signals/signals_flutter.dart';

class ProfileSwitchRepository extends ModelRepository<ProfileSwitch> {
  ProfileSwitchRepository() : super(profileSwitchTableName, timestampField: "start");

  @override
  ProfileSwitch fromMap(Map<String, Object?> map) {
    return ProfileSwitch(
      id: map["id"] as int?,
      eid: map["eid"] as String,
      name: map["name"] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"] as int),
      duration: map["duration"] as int,
      percentage: map["percentage"] as int,
    );
  }

  @override
  Map<String, Object> toSQLMap(ProfileSwitch model) {
    return {
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "percentage": model.percentage,
      "name": model.name,
      "eid": model.eid!,
    };
  }
}

class ProfileSwitch extends Model {
  static final ProfileSwitchRepository _q = ProfileSwitchRepository();

  @override
  ModelRepository get repository => _q;

  @override
  get date => startDate;

  final DateTime startDate;
  final int duration;
  final int percentage;
  final String name;

  ProfileSwitch({
    super.id,
    required super.eid,
    required this.startDate,
    required this.duration,
    required this.percentage,
    required this.name,
  });

  static Signal<int> get writeSignal => _q.writeSignal;
  static Future<int> saveAll(List<ProfileSwitch> models) => _q.saveAll(models);
}
