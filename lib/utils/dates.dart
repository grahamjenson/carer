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
}
