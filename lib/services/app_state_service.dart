import 'package:carer/models/clean_sgv.dart';

class AppStateService {
  //singleton
  static final AppStateService _instance = AppStateService._();
  factory AppStateService() => _instance;
  AppStateService._();

  Map<String, dynamic> appState() {
    CleanSGV? lastSGV = CleanSGV.lastSGV.value;
    return {
      "lastSGV": lastSGV?.toString(),
      "LastSGVStr": lastSGV?.unitStr(),
      "lastSGVAgeInMinutes": lastSGV?.age.inMinutes,
      "previousReadings": lastSGV?.before12.map((e) => e.toString()).toList(),
      "predictions": lastSGV?.predictions?.map((e) => e?.toString()).toList(),
    };
  }
}
