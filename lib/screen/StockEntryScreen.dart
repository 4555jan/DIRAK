import 'package:flutter/material.dart';

const variantType = {
  'Wingz GP Logo T-Shirt New': 'size',
  'Wildfoot Tango Tan': 'size',
  'Colonal Jersey': 'item',
  'Buckle': 'item',
  'NCC All Item': 'item',
  'Ceremonial Item NCC': 'item',
  'Scout and Guide All Items': 'item',
  'Scout and Guide Fabric': 'item',
  'Summer Cap': 'item',
  'unknown': 'item',
  'Leather Belt': 'item',
  'Nylon Belt': 'item',
  'Cut Socks': 'item',
  'Long Socks': 'item',
  'Items': 'item',
  'Colonal Jersey	': 'item',
  'Oswal Jersey	': 'item',
  'Colonal Jersey Patali				': 'item',
  'oswell jersey black': 'item',
  'shoulder badge': 'item',
  'Khakhi Jacket Full Sleeve': 'item',
  'Khakhi Jacket Half Sleeve': 'item',
  'Lanyard': 'item',
  'G-Oswal Fabric': 'item',
};

const sizeOptions = ['S', 'M', 'L', 'XL', 'XXL'];

class StockEntryScreen extends StatefulWidget {
  final String barcode;
  final String subcategory;

  const StockEntryScreen({super.key, required this.barcode, required this.subcategory});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  String? selectedSize;
  final itemController = TextEditingController();
  final stockInController = TextEditingController();
  final stockOutController = TextEditingController();

  String get variant => variantType[widget.subcategory] ?? 'item';

  void submit() {
    final stockIn = int.tryParse(stockInController.text) ?? 0;
    final stockOut = int.tryParse(stockOutController.text) ?? 0;

    final name = variant == 'size' ? selectedSize : itemController.text.trim();
    if (name == null || name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter valid ${variant == 'size' ? 'size' : 'item name'}')));
      return;
    }

    debugPrint("Submitted: Barcode=${widget.barcode}, Name=$name, StockIn=$stockIn, StockOut=$stockOut");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Stock Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Barcode: ${widget.barcode}"),
            const SizedBox(height: 16),
            if (variant == 'size')
              DropdownButtonFormField(
                value: selectedSize,
                items: sizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => selectedSize = val),
                decoration: const InputDecoration(labelText: "Select Size"),
              )
            else
              TextField(
                controller: itemController,
                decoration: const InputDecoration(labelText: "Enter Item Name"),
              ),
            TextField(
              controller: stockInController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock In"),
            ),
            TextField(
              controller: stockOutController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock Out"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: submit, child: const Text("Submit"))
          ],
        ),
      ),
    );
  }
}
