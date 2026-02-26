import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/presentation/widgets/qr/show_qr.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/presentation/widgets/invoice/customer_info.dart';
import 'package:stc_client/presentation/widgets/invoice/invoice_info.dart';
import 'package:stc_client/presentation/widgets/invoice/items_info.dart';
import 'package:stc_client/presentation/widgets/invoice/send_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/sign_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/supplier_info.dart';
import 'package:stc_client/presentation/widgets/invoice/totals_info.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  final Color appBarAndButtonColor = const Color(0xFF2C365A);
  final Color pageBackgroundColor = const Color(0xFFFFFFFF);

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  InvoiceFormController? c;
  late final ScrollController scrollController;
  late final TextEditingController xmlController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    xmlController = TextEditingController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final controller = await InvoiceFormController.create();

    if (!mounted) return;

    setState(() {
      c = controller;
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    xmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    if (c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = c!;

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
              provider.refreshInvoice();
              xmlController.clear();
              controller.clearAll();
            },
          ),
        ],
      ),
      body: Container(
        color: widget.pageBackgroundColor,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// LEFT SIDE FORM
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    InvoiceInfoSection(c: controller),
                    const SizedBox(height: 20),
                    SupplierSection(c: controller),
                    const SizedBox(height: 20),
                    CustomerSection(c: controller),
                    const SizedBox(height: 20),
                    InvoiceItemsSection(
                      items: controller.items,
                      onDelete:
                          (index) =>
                              setState(() => controller.removeItem(index)),
                    ),
                    const SizedBox(height: 20),

                    /// Totals
                    ValueListenableBuilder<double>(
                      valueListenable: controller.subtotal,
                      builder: (_, subtotal, __) {
                        return ValueListenableBuilder<double>(
                          valueListenable: controller.taxTotal,
                          builder: (_, taxTotal, __) {
                            return ValueListenableBuilder<double>(
                              valueListenable: controller.grandTotal,
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
                      c: controller,
                      color: widget.appBarAndButtonColor,
                      xmlController: xmlController,
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 20),

            /// RIGHT SIDE PREVIEW
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
                        provider.signedXml = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SendInvoiceButton(
                    c: controller,
                    color: widget.appBarAndButtonColor,
                    xmlController: xmlController,
                  ),
                  provider.qrBase64 != null ?
                    Center(
                      child: ShowQr(qrBase64: provider.qrBase64!.substring(1,900))
                    )
                    : const SizedBox.shrink()
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
