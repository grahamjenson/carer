import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/sgv.dart';

class AppDetailsService {
  //singleton
  static final AppDetailsService _instance = AppDetailsService._();
  factory AppDetailsService() => _instance;
  AppDetailsService._();

  Map<String, dynamic> appDetails() {
    CleanSGV? lastSGV = CleanSGV.lastSGV.value;
    return {
      "lastSGV": sgvPrinter(lastSGV),
      "previousReadings": lastSGV?.before12.map((e) => shortSGVPrinter(e)).toList(),
      "predictions": lastSGV?.predictions?.map((e) => shortSGVPrinter(e)).toList(),
    };
  }

  String sgvPrinter(ASGV? sgv) {
    if (sgv == null) {
      return "N/A";
    }
    var date = sgv.date;
    return "${sgv.unitStr()}@${date.hour}:${date.minute} (${sgv.minsAgo}m ago)";
  }

  String shortSGVPrinter(ASGV? sgv) {
    if (sgv == null) {
      return "N/A";
    }
    return "${sgv.unitStr()}@(${sgv.minsAgo}m)";
  }
}
