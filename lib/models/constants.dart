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
      default:
        return true;
    }
  }

  String get name {
    switch (this) {
      case Unit.mmol:
        return 'mmol/L';
      case Unit.mg:
        return 'mg/dl';
      default:
        return "mmol/L";
    }
  }

  double val(num value) {
    switch (this) {
      case Unit.mg:
        return value.toDouble();
      case Unit.mmol:
        return (value / MGtoMMOL).toDouble();
    }
  }

  String str(num value) {
    switch (this) {
      case Unit.mmol:
        return (value.toDouble() / MGtoMMOL).toStringAsFixed(1);
      case Unit.mg:
        return value.toDouble().toStringAsFixed(0);
      default:
        return value.toDouble().toStringAsFixed(0);
    }
  }

  static Unit fromBool(bool? b) {
    if (b == false) {
      return Unit.mg;
    } else {
      return Unit.mmol; // default on null
    }
  }
}
