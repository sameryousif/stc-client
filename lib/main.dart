import 'package:flutter/material.dart';
import 'pages/invoice_page.dart';

void main() {
  runApp(const STCInvoiceApp());
}

class STCInvoiceApp extends StatelessWidget {
  const STCInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "STC Invoice Generator",
      home: InvoicePage(),
    );
  }
}
