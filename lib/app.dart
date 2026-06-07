import 'package:flutter/material.dart';
import 'package:stc_client/presentation/screens/enrollment_page.dart';
import 'package:stc_client/presentation/screens/home_page.dart';
import 'package:stc_client/presentation/screens/invoice_page.dart';

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
      home: const HomePage(),
      routes: {
        '/invoice': (context) => const InvoicePage(),
        '/enrollment': (context) => const EnrollmentPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
