class Dates {
  static String dateAgoFromMills(DateTime? mills) {
    if (mills == null) return "";
    var now = DateTime.now();
    var diff = now.difference(mills);
    var minutes = diff.inMinutes;
    if (minutes < 60) {
      return "$minutes minutes ago";
    }
    var hours = diff.inHours;
    if (hours < 24) {
      return "$hours hours ago";
    }
    var days = diff.inDays;
    return "$days days ago";
  }

  static String dateAgoFromNow(DateTime? mills) {
    if (mills == null) return "";
    return dateAgoFromMills(mills);
  }
}
