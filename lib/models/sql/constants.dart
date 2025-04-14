const MGtoMMOL = 18.018;

enum Unit {
  mmol,
  mg;

  bool toBool() {
    switch (this) {
      case Unit.mmol:
        return true;
      case Unit.mg:
        return false;
    }
  }

  String get name {
    switch (this) {
      case Unit.mmol:
        return 'mmol/L';
      case Unit.mg:
        return 'mg/dl';
    }
  }

  double val(num value) {
    switch (this) {
      case Unit.mg:
        return value.toDouble();
      case Unit.mmol:
        return (value.toDouble() / MGtoMMOL).toDouble();
    }
  }

  String str(num value) {
    switch (this) {
      case Unit.mg:
        return value.toStringAsFixed(0);
      case Unit.mmol:
        return (value.toDouble() / MGtoMMOL).toStringAsFixed(1);
    }
  }

  double? fromStr(String val) {
    double? maybeValue = double.tryParse(val);
    if (maybeValue == null) {
      return null;
    }

    switch (this) {
      case Unit.mg:
        return maybeValue;
      case Unit.mmol:
        return maybeValue * MGtoMMOL;
    }
  }

  String strWithUnit(num value) {
    return '${str(value)}$name';
  }

  static Unit fromBool(bool? b) {
    if (b == false) {
      return Unit.mg;
    } else {
      return Unit.mmol; // default on null
    }
  }
}
