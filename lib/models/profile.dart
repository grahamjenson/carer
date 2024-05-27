class Profile {
  final int value;
  final DateTime date;

  Profile({
    required this.value,
    required this.date,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      value: map["value"],
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"]),
    );
  }
}
