import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/presentation/widgets/invoice/gen_clearnance_btn.dart';
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
                    const SizedBox(height: 16),
                    SupplierSection(c: controller),
                    const SizedBox(height: 16),
                    CustomerSection(c: controller),
                    const SizedBox(height: 16),
                    InvoiceItemsSection(
                      items: controller.items,
                      onDelete:
                          (index) =>
                              setState(() => controller.removeItem(index)),
                    ),
                    const SizedBox(height: 16),
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
                    GenrateReportingInvoice(
                      c: controller,
                      color: widget.appBarAndButtonColor,
                      xmlController: xmlController,
                    ),
                    const SizedBox(height: 16),
                    GenrateClearanceInvoice(
                      c: controller,
                      color: widget.appBarAndButtonColor,
                      xmlController: xmlController,
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
                      Text(
                        provider.showJson ? "JSON" : "XML",
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ClearInvoiceButton(
                          c: controller,
                          color: widget.appBarAndButtonColor,
                          xmlController: xmlController,
                          responseController: responseController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReportInvoiceButton(
                          c: controller,
                          color: widget.appBarAndButtonColor,
                          xmlController: xmlController,
                          responseController:
                              responseController, // Pass it here
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
