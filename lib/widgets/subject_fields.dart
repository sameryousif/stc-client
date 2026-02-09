import 'package:flutter/material.dart';

class SubjectFields extends StatelessWidget {
  final TextEditingController cnCtrl;
  final TextEditingController oCtrl;
  final TextEditingController ouCtrl;
  final TextEditingController cCtrl;
  final TextEditingController stCtrl;
  final TextEditingController lCtrl;
  final TextEditingController serialCtrl;

  const SubjectFields({
    super.key,
    required this.cnCtrl,
    required this.oCtrl,
    required this.ouCtrl,
    required this.cCtrl,
    required this.stCtrl,
    required this.lCtrl,
    required this.serialCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _rowFields(
          _field('Common Name (CN)', cnCtrl),
          _field('Organization (O)', oCtrl),
        ),
        _rowFields(
          _field('Organizational Unit (OU)', ouCtrl),
          _field('Country (C)', cCtrl),
        ),
        _rowFields(_field('State (ST)', stCtrl), _field('Locality (L)', lCtrl)),
        _rowFields(
          _field('Serial Number', serialCtrl),
          const SizedBox(),
        ), // empty to fill second half
      ],
    );
  }

  Widget _rowFields(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true, // makes field slightly smaller
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
    );
  }
}
