import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/providers/CertificateProvider.dart';
import 'package:stc_client/services/crypto_service.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First Page')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to the STC Certificate Generator!',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // final csrFile = await loadCsrFromPath();
                  final provider = Provider.of<CertificateProvider>(
                    context,
                    listen: false,
                  );
                  await provider.enrollCertificate();
                  //await sendCsrAndSaveCert(csrFile!);
                  /* Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InvoicePage()),
                  );*/
                },
                child: const Text('Generate Certificate'),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  CryptoService cryptoService = CryptoService();
                  await cryptoService.generateKeyAndCsr();
                  // Navigate to InvoicePage
                  /*Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InvoicePage()),
                  );*/
                },
                child: const Text('Generate private key and CSR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
