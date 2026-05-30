import 'package:flutter/material.dart';

class CustomField extends StatefulWidget {
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  final String? Function(String)? validator;
  final bool compact;

  const CustomField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.readOnly = false,
    this.validator,
    this.compact = false,
  });

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(CustomField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    if (widget.validator != null) {
      setState(() {
        _error = widget.validator!(v);
      });
    }
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: widget.compact ? const TextStyle(fontSize: 13) : null,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: widget.compact
            ? const TextStyle(fontSize: 12)
            : null,
        border: const OutlineInputBorder(),
        errorText: _error,
        isDense: widget.compact,
        contentPadding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
            : null,
      ),
      controller: _controller,
      onChanged: _onChanged,
      readOnly: widget.readOnly,
    );
  }
}
