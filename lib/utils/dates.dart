class Dates {
  static String dateAgoFromMills(DateTime? mills) {
    if (mills == null) return "";
    var now = DateTime.now();
    var diff = now.difference(mills);
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

  static String dateAgoShort(DateTime? mills) {
    if (mills == null) return "";
    var now = DateTime.now();
    // returns time ago in format 1d 2h 3m
    var diff = now.difference(mills);

    if (diff.inHours > 0) {
      return "${diff.inHours}h ${diff.inMinutes % 60}m ago";
    }
    return "${diff.inMinutes}m ago";
  }

  static final DateTime earliest = DateTime.fromMillisecondsSinceEpoch(0);
}
