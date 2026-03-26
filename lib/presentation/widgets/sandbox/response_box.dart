import 'package:flutter/material.dart';

class ResponseBox extends StatelessWidget {
  final ValueNotifier<String> notifier;

  const ResponseBox({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, value, __) {
        return Container(
          height: 240,
          width: 600,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              value.isEmpty ? "Response will appear here..." : value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        );
      },
    );
  }
}
