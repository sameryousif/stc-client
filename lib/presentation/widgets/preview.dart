import 'package:flutter/material.dart';

// Widget that displays a preview of content, used in various parts of the app to show a scrollable preview of text content such as CSRs or invoice data
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
