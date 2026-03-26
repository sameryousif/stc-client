import 'package:flutter/material.dart';
import 'package:stc_client/presentation/screens/enrollment_page.dart';
import 'package:stc_client/presentation/screens/invoice_page.dart';
import 'package:stc_client/presentation/screens/sandBoxPage.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STC Client',
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          ),
        ),
      ),
      home: SandboxPage(),
      routes: {'/invoice': (context) => const InvoicePage()},
      debugShowCheckedModeBanner: false,
    );
  }
}
