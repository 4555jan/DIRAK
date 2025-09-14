import 'package:flutter/material.dart';

class EditStockEntryScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String variant;
  final String category;
  final String subcategory;

  const EditStockEntryScreen({
    super.key,
    required this.initialData,
    required this.variant,
    required this.category,
    required this.subcategory,
  });

  @override
  State<EditStockEntryScreen> createState() => _EditStockEntryScreenState();
}

class _EditStockEntryScreenState extends State<EditStockEntryScreen> {
  late TextEditingController nameController;
  late TextEditingController stockInController;
  late TextEditingController stockOutController;
  late TextEditingController stockController;
  late TextEditingController totalstockhitcontroller;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.initialData['name'] ?? widget.initialData['size'] ?? '',
    );
    stockInController = TextEditingController(
      text: widget.initialData['stockIn']?.toString() ?? '0',
    );
    stockOutController = TextEditingController(
      text: widget.initialData['stockOut']?.toString() ?? '0',
    );
    stockController = TextEditingController(
      text: widget.initialData['stock']?.toString() ?? '0',
    );
    totalstockhitcontroller = TextEditingController(
      text: widget.initialData['totalstockhit']?.toString() ?? '0',
    );
  }
void saveEntry() {
  final name = nameController.text.trim();
  final stockIn = int.tryParse(stockInController.text) ?? 0;
  final stockOut = int.tryParse(stockOutController.text) ?? 0;
  final stock = int.tryParse(stockController.text) ?? 0;
  final totalstockhit = int.tryParse(totalstockhitcontroller.text) ?? 0;

  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a name or size")),
    );
    return;
  }

  final now = DateTime.now().toUtc().toIso8601String();

  final entry = {
    'id': widget.initialData['id'] ?? DateTime.now().millisecondsSinceEpoch,
    'name': widget.variant == 'item' ? name : null,
    'size': widget.variant == 'size' ? name : null,
    'stockIn': stockIn,
    'stockOut': stockOut,
    'stock': stock,
    'totalStock': stockIn - stockOut,
    'totalstockhit': totalstockhit, // ✅ ADD THIS LINE
    'barcode': widget.initialData['barcode'] ??
        '${widget.subcategory.toLowerCase().replaceAll(' ', '_')}_${name.toLowerCase().replaceAll(' ', '_')}',
    'category': widget.category,
    'subcategory': widget.subcategory,
    'created_at': widget.initialData['created_at'] ?? now,
    'updated_at': now,
  };

  Navigator.pop(context, entry);
}


  void updateStock(TextEditingController controller, int delta) {
    int current = int.tryParse(controller.text) ?? 0;
    current = (current + delta).clamp(0, 999999); // prevent negatives
    controller.text = current.toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    stockInController.dispose();
    stockOutController.dispose();
    stockController.dispose();
    totalstockhitcontroller.dispose();

    super.dispose();
  }

  Widget stockInputField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () => setState(() => updateStock(controller, -1)),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => setState(() => updateStock(controller, 1)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Stock Entry")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: widget.variant == 'size' ? 'Size' : 'Item Name',
                ),
              ),
              const SizedBox(height: 10),
              stockInputField("Stock In", stockInController),
              const SizedBox(height: 10),
              stockInputField("Stock Out", stockOutController),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stock"),
              ),
              TextField(
                controller: totalstockhitcontroller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "totalhit"),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: saveEntry,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
