import 'package:flutter/material.dart';

/// Base stateless widget
class BaseWidget extends StatelessWidget {
  final String title;

  const BaseWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Text('Base Widget'),
      ),
    );
  }
}
