import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stc_client/models/controllers/invoice_controller.dart';
import 'package:stc_client/providers/InvoiceProvider.dart';
import 'package:stc_client/widgets/invoice/customer_info.dart';
import 'package:stc_client/widgets/invoice/invoice_info.dart';
import 'package:stc_client/widgets/invoice/items_info.dart';
import 'package:stc_client/widgets/invoice/send_btn.dart';
import 'package:stc_client/widgets/invoice/sign_btn.dart';
import 'package:stc_client/widgets/invoice/supplier_info.dart';
import 'package:stc_client/widgets/invoice/totals_info.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});
  final Color appBarAndButtonColor = const Color(0xFF2C365A);
  final Color pageBackgroundColor = const Color(0xFFEEE8DF);

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late final InvoiceFormController c;
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    c = InvoiceFormController();
    c.initDefaults(() => setState(() {}));
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    c.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "STC Invoice Generator",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.appBarAndButtonColor,
        actions: [
          IconButton(
            tooltip: "Refresh Invoice",
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              final provider = context.read<InvoiceProvider>();
              provider.refreshInvoice();
              // optionally, clear your form controller as well
              c.clearAll();

              c.initDefaults(() => setState(() {}));
              scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: widget.pageBackgroundColor,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ////form left side
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    InvoiceInfoSection(c: c),
                    const SizedBox(height: 20),
                    SupplierSection(c: c),
                    const SizedBox(height: 20),
                    CustomerSection(c: c),
                    const SizedBox(height: 20),
                    InvoiceItemsSection(
                      items: c.items,
                      onDelete: (index) => setState(() => c.removeItem(index)),
                    ),
                    const SizedBox(height: 20),
                    InvoiceTotalsSection(
                      subtotal: c.subtotal,
                      taxTotal: c.taxTotal,
                      grandTotal: c.grandTotal,
                    ),
                    const SizedBox(height: 20),

                    // Generate & Sign Button
                    SizedBox(height: 20),
                    SignInvoiceButton(
                      c: c,
                      color: widget.appBarAndButtonColor,
                      xmlController: c.xmlController,
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 20),

            ///right side preview and send
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: const Text(
                      "Signed XML Preview",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: c.xmlController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "XML will appear here",
                      ),
                      onChanged: (value) {
                        if (!provider.isGenerating) {
                          provider.signedXml = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Send Button
                  SizedBox(height: 20),
                  SendInvoiceButton(
                    c: c,
                    color: widget.appBarAndButtonColor,
                    xmlController: c.xmlController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
