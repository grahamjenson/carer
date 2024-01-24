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

  static final DateTime earliest = DateTime.fromMillisecondsSinceEpoch(0);
}
