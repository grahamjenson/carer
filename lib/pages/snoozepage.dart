import 'package:flutter/material.dart';

class SnoozePage extends StatelessWidget {
  const SnoozePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Snooze'),
        ),
        body: const Center(
          child: Text(
            'Snooze',
            style: TextStyle(fontSize: 24),
          ),
        ));
  }
}
