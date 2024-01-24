import 'dart:async';
import 'dart:developer';

import 'package:carer/models/settings_cn.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:flutter/material.dart';

class SummaryCN extends ChangeNotifier {
  Settings settings;

  // When this updates lots of things will change
  Summary summary = Summary.empty();
  bool _summaryToBeUpdated = true;

  SummaryCN({required this.settings}) {
    Timer.periodic(const Duration(seconds: 5), (Timer t) => update());
    update();
    settings.addListener(() {
      _summaryToBeUpdated = true;
    });
  }

  update() {
    if (summary.ageInSeconds() > 15) {
      _summaryToBeUpdated = true;
    }

    if (_summaryToBeUpdated) {
      _summaryToBeUpdated = false;
      var (nsURL, nsToken) = settings.nightscoutURLAndToken;
      NSClient().getSummary(nsURL, nsToken).catchError((e) {
        log("GETTING SUMMARY ERROR: $e");
        _summaryToBeUpdated = true;
        return Summary.empty();
      }).then((value) {
        summary = value;
        notifyListeners();
      });
    }
  }
}
