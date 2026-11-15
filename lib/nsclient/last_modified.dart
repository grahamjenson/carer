import 'dart:convert';

import 'package:carer/nsclient/ns_type.dart';

class NSLastModified {
  int devicestatus;
  int entries;
  int food;
  int profile;
  int settings;
  int treatments;
  String raw;
  Map<String, int> lastModifiedMap;
  NSLastModified({
    required this.devicestatus,
    required this.entries,
    required this.food,
    required this.profile,
    required this.settings,
    required this.treatments,
    required this.lastModifiedMap,
    required this.raw,
  });

  factory NSLastModified.fromJson(String jsonStr) {
    final Map<String, dynamic> jsonMap = json.decode(jsonStr);

    var result = jsonMap['result'];
    result ??= {};
    var collections = result['collections'];
    collections ??= {};
    var lastModifiedMap = {
      'devicestatus': NSType.getInt(collections['devicestatus'], defaultValue: 0)!,
      'entries': NSType.getInt(collections['entries'], defaultValue: 0)!,
      'food': NSType.getInt(collections['food'], defaultValue: 0)!,
      'profile': NSType.getInt(collections['profile'], defaultValue: 0)!,
      'settings': NSType.getInt(collections['settings'], defaultValue: 0)!,
      'treatments': NSType.getInt(collections['treatments'], defaultValue: 0)!,
    };

    return NSLastModified(
      lastModifiedMap: lastModifiedMap,
      devicestatus: lastModifiedMap['devicestatus']!,
      entries: lastModifiedMap['entries']!,
      food: lastModifiedMap['food']!,
      profile: lastModifiedMap['profile']!,
      settings: lastModifiedMap['settings']!,
      treatments: lastModifiedMap['treatments']!,
      raw: jsonStr,
    );
  }

  factory NSLastModified.empty() {
    return NSLastModified(
      lastModifiedMap: {
        'devicestatus': 0,
        'entries': 0,
        'food': 0,
        'profile': 0,
        'settings': 0,
        'treatments': 0,
      },
      devicestatus: 0,
      entries: 0,
      food: 0,
      profile: 0,
      settings: 0,
      treatments: 0,
      raw: '',
    );
  }
}
