import 'package:provider/provider.dart';
import 'package:stc_client/providers/InvoiceProvider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../widgets/custom_field.dart';
import '../widgets/section_title.dart';
import '../widgets/totals_row.dart';
import '../widgets/item_card.dart';
import '../models/invoice_item.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  // -------------------------------------------------------------
  // ALL CONTROLLERS
  // -------------------------------------------------------------

  // Invoice info
  final invoiceNumber = TextEditingController();
  final invoiceDate = TextEditingController();
  final invoiceType = TextEditingController();
  final currencyCode = TextEditingController();

  // Supplier info
  final supplierName = TextEditingController();
  final supplierTIN = TextEditingController();
  final supplierAddress = TextEditingController();
  final supplierCity = TextEditingController();
  final supplierCountry = TextEditingController();
  final supplierPhone = TextEditingController();
  final supplierEmail = TextEditingController();

  // Customer info
  final customerName = TextEditingController();
  final customerTIN = TextEditingController();
  final customerAddress = TextEditingController();
  final customerCity = TextEditingController();
  final customerCountry = TextEditingController();
  final customerPhone = TextEditingController();
  final customerEmail = TextEditingController();

  final String privateKeyPath = r'C:\openssl_keys\merchant_private.key';
  final String csrPath = r'C:\openssl_keys\merchant_csr.pem';
  // Items list
  List<InvoiceItem> items = [];

  @override
  void initState() {
    super.initState();

    // Auto-fill basic data
    invoiceNumber.text = const Uuid().v4();
    invoiceDate.text = DateTime.now().toString().split(' ').first;
    invoiceType.text = "380";
    currencyCode.text = "SDG";

    // Supplier info
    supplierName.text = "My Supplier";
    supplierTIN.text = "123456789";
    supplierAddress.text = "Khartoum Bahri";
    supplierCity.text = "Khartoum";
    supplierCountry.text = "SD";
    supplierPhone.text = "+249912345678";
    supplierEmail.text = "supplier@example.com";

    // Customer info
    customerName.text = "Default Customer";
    customerTIN.text = "5566778899";
    customerAddress.text = "Omdurman";
    customerCity.text = "Omdurman";
    customerCountry.text = "SD";
    customerPhone.text = "+249911111111";
    customerEmail.text = "customer@example.com";

    // Add first item
    final firstItem = InvoiceItem(
      name: "Laptop",
      description: "Dell",
      quantity: 2,
      unitPrice: 1500,
      taxRate: 15,
    );
    _addItemListeners(firstItem);
    items.add(firstItem);
  }

  // Add listeners to recalc totals when any field changes
  void _addItemListeners(InvoiceItem item) {
    item.quantityController.addListener(_recalculate);
    item.unitPriceController.addListener(_recalculate);
    item.taxRateController.addListener(_recalculate);
  }

  void _recalculate() {
    setState(() {}); // Rebuild UI to update totals
  }

  // Totals
  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.quantity * item.unitPrice);

  double get taxTotal =>
      items.fold(0, (sum, item) => sum + item.total * (item.taxRate / 100));

  double get grandTotal => subtotal + taxTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("STC Invoice Generator")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------------------------------------------------------------
            // INVOICE INFO
            // -------------------------------------------------------------
            SectionTitle("Invoice Information"),
            CustomField(
              controller: invoiceNumber,
              label: "Invoice Number",
              readOnly: true,
            ),
            CustomField(controller: invoiceDate, label: "Invoice Date"),
            CustomField(controller: invoiceType, label: "Invoice Type"),
            CustomField(controller: currencyCode, label: "Currency Code"),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // SUPPLIER
            // -------------------------------------------------------------
            SectionTitle("Supplier Information"),
            CustomField(controller: supplierName, label: "Supplier Name"),
            CustomField(controller: supplierTIN, label: "Supplier TIN"),
            CustomField(controller: supplierAddress, label: "Supplier Address"),
            CustomField(controller: supplierCity, label: "Supplier City"),
            CustomField(controller: supplierCountry, label: "Supplier Country"),
            CustomField(controller: supplierPhone, label: "Supplier Phone"),
            CustomField(controller: supplierEmail, label: "Supplier Email"),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // CUSTOMER
            // -------------------------------------------------------------
            SectionTitle("Customer Information"),
            CustomField(controller: customerName, label: "Customer Name"),
            CustomField(controller: customerTIN, label: "Customer TIN"),
            CustomField(controller: customerAddress, label: "Customer Address"),
            CustomField(controller: customerCity, label: "Customer City"),
            CustomField(controller: customerCountry, label: "Customer Country"),
            CustomField(controller: customerPhone, label: "Customer Phone"),
            CustomField(controller: customerEmail, label: "Customer Email"),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // ITEMS
            // -------------------------------------------------------------
            SectionTitle("Invoice Items"),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder:
                  (context, index) => ItemCard(
                    item: items[index],
                    onDelete: () {
                      setState(() {
                        items.removeAt(index);
                      });
                    },
                  ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // TOTALS
            // -------------------------------------------------------------
            SectionTitle("Totals"),
            TotalsRow(title: "Subtotal", value: subtotal),
            TotalsRow(title: "Tax Total", value: taxTotal),
            TotalsRow(title: "Grand Total", value: grandTotal, bold: true),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // BUTTON
            // -------------------------------------------------------------
            ElevatedButton(
              onPressed: () async {
                final provider = context.read<InvoiceProvider>();
                await provider.generateAndSendInvoice(
                  invoiceNumber: invoiceNumber.text,
                  items: items,
                  supplierInfo: {
                    "name": supplierName.text,
                    "vat": supplierTIN.text,
                  },
                  customerInfo: {
                    "name": customerName.text,
                    "vat": customerTIN.text,
                  },
                );
              },
              child:
                  context.watch<InvoiceProvider>().isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Send to Server"),
            ),
          ],
        ),
      ),
    );
  }
}
