import 'package:flutter/material.dart';

class Preview extends StatelessWidget {
  final String content;
  final double height;

  const Preview({super.key, required this.content, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: height,
        child: SingleChildScrollView(
          child: Text(
            content.isEmpty ? '— Empty —' : content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ),
    );
  }
}
