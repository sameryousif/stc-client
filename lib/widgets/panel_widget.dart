import 'package:flutter/material.dart';
import 'package:stc_client/widgets/preview.dart';
import 'package:stc_client/widgets/subject_fields.dart';

class LeftPanel extends StatelessWidget {
  final String privateKey;
  final TextEditingController cnCtrl;
  final TextEditingController oCtrl;
  final TextEditingController ouCtrl;
  final TextEditingController cCtrl;
  final TextEditingController stCtrl;
  final TextEditingController lCtrl;
  final TextEditingController serialCtrl;
  final VoidCallback onGenerateCsr;

  const LeftPanel({
    super.key,
    required this.privateKey,
    required this.cnCtrl,
    required this.oCtrl,
    required this.ouCtrl,
    required this.cCtrl,
    required this.stCtrl,
    required this.lCtrl,
    required this.serialCtrl,
    required this.onGenerateCsr,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Private Key',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Preview(content: privateKey, height: 150),

          const SizedBox(height: 16),
          const Text(
            'CSR Subject Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          SubjectFields(
            cnCtrl: cnCtrl,
            oCtrl: oCtrl,
            ouCtrl: ouCtrl,
            cCtrl: cCtrl,
            stCtrl: stCtrl,
            lCtrl: lCtrl,
            serialCtrl: serialCtrl,
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Color(0xFF2C365A),
            ),
            label: const Text(
              'Generate New CSR & Key',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: onGenerateCsr,
          ),
        ],
      ),
    );
  }
}

class RightPanel extends StatelessWidget {
  final String csr;
  final String certificate;
  final TextEditingController tokenCtrl;
  final VoidCallback onGenerateCert;

  const RightPanel({
    super.key,
    required this.csr,
    required this.certificate,
    required this.tokenCtrl,
    required this.onGenerateCert,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Generated CSR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Preview(content: csr, height: 150),

          const SizedBox(height: 16),
          const Text(
            'Enrollment Token',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextField(
            controller: tokenCtrl,
            decoration: const InputDecoration(
              labelText: 'Insert Token',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Color(0xFF2C365A),
            ),
            label: const Text(
              'Generate Certificate',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: onGenerateCert,
          ),

          const SizedBox(height: 16),
          const Text(
            'Received Certificate',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Preview(content: certificate, height: 150),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Color(0xFF2C365A),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/invoice');
            },
            child: const Text(
              'Go to Invoice Page',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
