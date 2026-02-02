import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/providers/CertificateProvider.dart';
import 'package:stc_client/services/crypto_service.dart';
import 'package:stc_client/utils/tools_paths.dart';

class FirstPage extends StatelessWidget {
  FirstPage({Key? key}) : super(key: key);
  final CryptoService cryptoService = CryptoService();

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
                  final provider = Provider.of<CertificateProvider>(
                    context,
                    listen: false,
                  );
                  await ToolPaths.ensureToolsReady();
                  await ToolPaths.verifyToolsExist();
                  /*if (!toolsOk) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please make sure all required tools are present in the tools folder.",
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                    return;
                  }*/
                  await provider.enrollCertificate();
                },
                child: const Text('Generate Certificate'),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await ToolPaths.ensureToolsReady();
                  await ToolPaths.verifyToolsExist();
                  /*if (toolsOk) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please make sure all required tools are present in the tools folder.",
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                    return;
                  }*/
                  await cryptoService.generateKeyAndCsr();
                },
                child: const Text('Generate private key and CSR'),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/invoice');
                },
                child: const Text('Go to Invoice Page'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
