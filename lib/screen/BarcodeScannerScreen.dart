// BarcodeScannerScreen.dart
import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'EditStockEntryScreen.dart';


class BarcodeScannerScreen extends StatefulWidget {
  final String subcategory;
  final String? category;
  final bool fromDashboard;

  const BarcodeScannerScreen({
    super.key,
    required this.subcategory,
    this.category,
    this.fromDashboard = false,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool isProcessing = false;

  void onDetect(BarcodeCapture capture) async {
    if (isProcessing || capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => isProcessing = true);

    final entry = await DatabaseHelper.instance.getEntryByBarcode(code);

    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No entry found for this barcode")),
      );
      setState(() => isProcessing = false);
      return;
    }

    final variant = _getVariant(entry['subcategory'] ?? '');

    final updatedEntry = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStockEntryScreen(
          initialData: entry,
          variant: variant,
          category: entry['category'] ?? '',
          subcategory: entry['subcategory'] ?? '',
        ),
      ),
    );

    if (updatedEntry != null && updatedEntry is Map<String, dynamic>) {
      await DatabaseHelper.instance.updateEntry(updatedEntry);

      if (widget.fromDashboard) {
        Navigator.pop(context); // back to dashboard
      } else {
        Navigator.pop(context, updatedEntry); // return to Subcat
      }
    } else {
      setState(() => isProcessing = false);
    }
  }

  String _getVariant(String subcategory) {
    const variantTypeMap = {
      'wingz gp logo t-shirt new': 'size',
      'wildfoot tango tan': 'size',
      'colonal jersey': 'item',
      'buckle': 'item',
      'ncc all item': 'item',
      'ceremonial item ncc': 'item',
      'scout and guide all items': 'item',
      'scout and guide fabric': 'item',
      'summer cap': 'item',
      'unknown': 'item',
      'leather belt': 'item',
      'nylon belt': 'item',
      'cut socks': 'item',
      'long socks': 'item',
      'items': 'item',
      'colonal jersey patali': 'item',
      'oswal jersey': 'item',
      'oswell jersey black': 'item',
      'shoulder badge': 'item',
      'khakhi jacket full sleeve': 'item',
      'khakhi jacket half sleeve': 'item',
      'lanyard': 'item',
      'g-oswal fabric': 'item',
    };
    final normalized = subcategory.trim().toLowerCase();
    return variantTypeMap[normalized] ?? 'size';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        onDetect: onDetect,
  
      ),
    );
  }
}
