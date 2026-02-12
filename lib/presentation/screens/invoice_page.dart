import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/presentation/widgets/invoice/customer_info.dart';
import 'package:stc_client/presentation/widgets/invoice/invoice_info.dart';
import 'package:stc_client/presentation/widgets/invoice/items_info.dart';
import 'package:stc_client/presentation/widgets/invoice/send_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/sign_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/supplier_info.dart';
import 'package:stc_client/presentation/widgets/invoice/totals_info.dart';

// Widget that displays the main invoice page, containing a form on the left side for users to input invoice information, supplier information, customer information, and invoice items, and a preview section on the right side to display the signed XML of the invoice, along with buttons to generate/sign the invoice and send it
class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  final Color appBarAndButtonColor = const Color(0xFF2C365A);
  final Color pageBackgroundColor = const Color(0xFFFFFFFF);

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late final InvoiceFormController c;
  late final ScrollController scrollController;
  final xmlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    c = InvoiceFormController();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
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
              c.clearAll();
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
            /// Left side form
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

                    /// Totals section using ValueListenableBuilder
                    ValueListenableBuilder<double>(
                      valueListenable: c.subtotal,
                      builder: (_, subtotal, __) {
                        return ValueListenableBuilder<double>(
                          valueListenable: c.taxTotal,
                          builder: (_, taxTotal, __) {
                            return ValueListenableBuilder<double>(
                              valueListenable: c.grandTotal,
                              builder: (_, grandTotal, __) {
                                return InvoiceTotalsSection(
                                  subtotal: subtotal,
                                  taxTotal: taxTotal,
                                  grandTotal: grandTotal,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SignInvoiceButton(
                      c: c,
                      color: widget.appBarAndButtonColor,
                      xmlController: xmlController,
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 20),

            /// Right side preview & send
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      "Signed XML Preview",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: xmlController,
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
                  const SizedBox(height: 20),
                  SendInvoiceButton(
                    c: c,
                    color: widget.appBarAndButtonColor,
                    xmlController: xmlController,
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
