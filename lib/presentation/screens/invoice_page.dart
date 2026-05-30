import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/presentation/widgets/invoice/gen_clearance_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/report_btn.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/presentation/widgets/invoice/customer_info.dart';
import 'package:stc_client/presentation/widgets/invoice/invoice_info.dart';
import 'package:stc_client/presentation/widgets/invoice/items_info.dart';
import 'package:stc_client/presentation/widgets/invoice/clear_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/gen_reporting_btn.dart';
import 'package:stc_client/presentation/widgets/invoice/supplier_info.dart';
import 'package:stc_client/presentation/widgets/invoice/totals_info.dart';
import 'dart:convert';
import 'package:stc_client/core/invoice/invoice_item.dart';

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
  late final TextEditingController responseController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    xmlController = TextEditingController();
    responseController = TextEditingController();
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
    responseController.dispose();
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
              scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              provider.refreshInvoice();
              xmlController.clear();
              responseController.clear();
              controller.clearAll();
              provider.showJson = false;
              // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
              provider.notifyListeners();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
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
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: SupplierSection(c: controller)),
                              const SizedBox(width: 8),
                              Expanded(child: CustomerSection(c: controller)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InvoiceItemsSection(
                            items: controller.items,
                            onDelete:
                                (index) =>
                                    setState(() => controller.removeItem(index)),
                            onChanged: () => controller.recalculateTotals(),
                            onAddItem: () => setState(
                              () => controller.addItem(
                                InvoiceItem(
                                  name: "New Item",
                                  description: "",
                                  quantity: 1,
                                  unitPrice: 0,
                                  taxRate: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                        ],
                      ),
                    ),
                  ),

                  const VerticalDivider(width: 20),

                  /// RIGHT SIDE PREVIEW + RESPONSE
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Preview mode toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Preview Mode",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: provider.showJson,
                              onChanged: (value) async {
                                if (value &&
                                    provider.lastDto == null &&
                                    provider.signedXml != null) {
                                  await provider.generateDtoFromXml();
                                }
                                provider.showJson = value;
                                // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                                provider.notifyListeners();
                              },
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "XML",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        provider.showJson ? Colors.black : Colors.red,
                                  ),
                                ),
                                const Text(" / "),
                                Text(
                                  "JSON",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        provider.showJson ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Expanded Preview
                        Expanded(flex: 2, child: _buildPreviewContent(provider)),
                        const SizedBox(height: 16),
                        Text(
                          "Response",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        // Server response read-only field
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: SelectableText(
                              responseController.text.isEmpty
                                  ? "Server response will appear here..."
                                  : responseController.text,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// FIXED BOTTOM BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: GenerateReportingInvoice(
                          c: controller,
                          color: widget.appBarAndButtonColor,
                          xmlController: xmlController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GenerateClearanceInvoice(
                          c: controller,
                          color: widget.appBarAndButtonColor,
                          xmlController: xmlController,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClearInvoiceButton(
                          c: controller,
                          color: widget.appBarAndButtonColor,
                          xmlController: xmlController,
                          responseController: responseController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ReportInvoiceButton(
                          c: controller,
                          color: widget.appBarAndButtonColor,
                          xmlController: xmlController,
                          responseController: responseController,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(InvoiceProvider provider) {
    if (provider.showJson) {
      if (provider.isGeneratingDto) {
        return const Center(child: CircularProgressIndicator());
      }
      if (provider.lastDto != null) {
        final jsonString = const JsonEncoder.withIndent(
          '  ',
        ).convert(provider.lastDto);
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        );
      } else {
        return Center(
          child: Text(
            "No JSON available. Please sign the invoice first.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        );
      }
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            xmlController.text.isEmpty
                ? "XML will appear here"
                : xmlController.text,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      );
    }
  }
}
