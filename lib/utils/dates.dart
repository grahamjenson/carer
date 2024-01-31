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

  static String dateAgoShort(Duration diff) {
    if (diff.inMinutes == 0) {
      return "now";
    }

    if (diff.inHours > 0) {
      return "${diff.inHours}h ${diff.inMinutes % 60}m ago";
    }
    return "${diff.inMinutes}m ago";
  }

  static final DateTime earliest = DateTime.fromMillisecondsSinceEpoch(0);
}
