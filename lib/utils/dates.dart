class Dates {
  static String dateAgoFromMills(Duration? diff) {
    if (diff == null) {
      return "";
    }
    var minutes = diff.inMinutes;
    if (minutes < 60) {
      return "${minutes}mins";
    }
    var hours = diff.inHours;
    if (hours < 24) {
      return "${hours}hours";
    }
    var days = diff.inDays;
    return "${days}days";
  }

  static String dateAgoShort(Duration diff, {hours = true}) {
    if (diff.inMinutes == 0) {
      return "now";
    }

    if (diff.inHours > 0 && hours) {
      return "${diff.inHours}h${diff.inMinutes % 60}m";
    }
    return "${diff.inMinutes}m";
  }

  static final DateTime earliest = DateTime.fromMillisecondsSinceEpoch(0);

  static String shortSecondsLeft(Duration duration) {
    var totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return "";
    }

    var hours = (totalSeconds / 3600).floor();
    var minutes = ((totalSeconds % 3600) / 60).floor();

    var minutesStr = "<1m";

    if (hours > 0) {
      if (minutes == 0) {
        return "${hours}h";
      }
      return "${hours}h${minutes}m";
    }

    if (minutes > 0) {
      return "${minutes}m";
    }

    return minutesStr;
  }

  static int secondsTillNext24HourTime(int timeAsHour) {
    DateTime now = DateTime.now();
    DateTime nextTime = DateTime(now.year, now.month, now.day, timeAsHour);

    if (now.isAfter(nextTime)) {
      // If it's already past 8 PM today, find 8 PM tomorrow
      nextTime = DateTime(now.year, now.month, now.day + 1, timeAsHour);
    }

    print("timeAsHour $timeAsHour, $now $nextTime ${now.timeZoneName}");

    Duration difference = nextTime.difference(now);
    return difference.inSeconds;
  }

  static String stringOf24HourTime(int timeAsHour) {
    // convert 24hour time to am pm
    if (timeAsHour > 12) {
      return "${timeAsHour - 12}PM";
    }
    return "${timeAsHour}AM";
  }
}
