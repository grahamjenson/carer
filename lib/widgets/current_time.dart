import 'dart:async';
import 'package:flutter/material.dart';

class CurrentTimeWidget extends StatefulWidget {
  const CurrentTimeWidget({super.key});

  @override
  CurrentTimeWidgetState createState() => CurrentTimeWidgetState();
}

class CurrentTimeWidgetState extends State<CurrentTimeWidget> {
  late String _timeString;
  late Timer _timer;

  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getTime() {
    final String formattedDateTime = _formatDateTime(DateTime.now());
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    //formats the dateTime as 'hh:mm' this forces each int to be 2 digits
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(_timeString,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
  }
}
