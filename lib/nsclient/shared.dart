class TimeValue {
  String time;
  double value;

  TimeValue({
    required this.time,
    required this.value,
  });

  factory TimeValue.fromJson(Map<String, dynamic> json) {
    return TimeValue(
      time: json['time'],
      value: json['value'].toDouble(),
    );
  }
}
