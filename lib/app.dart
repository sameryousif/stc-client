import 'package:flutter/material.dart';
import 'package:stc_client/screens/first_page.dart';
import 'package:stc_client/screens/invoice_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STC Client',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FirstPage(),
      routes: {'/invoice': (context) => const InvoicePage()},
      debugShowCheckedModeBanner: false,
    );
  }
}
