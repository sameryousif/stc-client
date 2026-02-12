import 'package:flutter/material.dart';

// Widget that displays a customizable text field, used in various parts of the app to allow users to input values for different fields such as invoice item details or certificate subject fields
class CustomField extends StatelessWidget {
  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  const CustomField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }
}
