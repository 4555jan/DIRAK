
import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:diraj_store/models/supabase_sync_helper.dart';
import 'package:flutter/material.dart';
import 'package:diraj_store/screen/EditStockEntryScreen.dart';
import 'package:diraj_store/screen/BarcodeScannerScreen.dart';

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

class Subcat extends StatefulWidget {
  final String title;
  final String category;

  const Subcat({super.key, required this.title, required this.category});

  @override
  State<Subcat> createState() => _SubcatState();
}

class _SubcatState extends State<Subcat> {
  late String variant;
  late String column1;
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    final normalizedTitle = widget.title.trim().toLowerCase();
    variant = variantTypeMap[normalizedTitle] ?? 'size';
    column1 = variant == 'size' ? 'Size' : 'Item';
    fetchEntries();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SupabaseHelper.instance.initRealtimeListener(
        onDataChanged: fetchEntries,
        context: context,
      );
    });
  }

  Future<void> fetchEntries() async {
    final data = await DatabaseHelper.instance.getEntriesForSubcategory(
      widget.title,
    );
      if (!mounted) return;
    setState(() => entries = data);
  }

  Future<void> openEditScreen({Map<String, dynamic>? entry}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStockEntryScreen(
          initialData: entry ?? {},
          category: widget.category,
          subcategory: widget.title,
          variant: variant,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (entry != null) {
        await DatabaseHelper.instance.updateEntry(result);
      } else {
        await DatabaseHelper.instance.insertEntry(result);
      }
      await fetchEntries();
    }
  }

  Future<void> deleteEntry(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteEntry(id);
      await fetchEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: const Color.fromARGB(243, 250, 242, 242),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BarcodeScannerScreen(
                    subcategory: widget.title,
                    category: widget.category,
                    fromDashboard: false,
                  ),
                ),
              );

              if (result != null && result is Map<String, dynamic>) {
                await DatabaseHelper.instance.updateEntry(result);
                await fetchEntries();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                DataColumn(label: Text(column1)),
                const DataColumn(label: Text('Stock In')),
                const DataColumn(label: Text('Stock Out')),
                const DataColumn(label: Text('Stock')),
                const DataColumn(label: Text('Total Stock')),
                const DataColumn(label: Text('Barcode')),
                const DataColumn(label: Text('Delete')),
              ],
              rows: entries.map((entry) {
                final nameOrSize = variant == 'size'
                    ? (entry['size'] ?? '')
                    : (entry['name'] ?? '');
                final stockIn = entry['stockIn'] ?? 0;
                final stockOut = entry['stockOut'] ?? 0;
                final stock = entry['stock'] ?? 0;
                final totalStock =  stock + stockIn - stockOut;
                final totalStockHit = entry['totalstockhit'] ?? 0;

                final isLimitReached =
                    totalStockHit > 0 && totalStock >= totalStockHit;

                return DataRow(
                  onSelectChanged: (_) => openEditScreen(entry: entry),
                  cells: [
                    DataCell(Text(nameOrSize)),
                    DataCell(Text('$stockIn')),
                    DataCell(Text('$stockOut')),
                    DataCell(Text('${entry['stock'] ?? 0}')),
                    DataCell(
                      Text(
                        '$totalStock',
                        style: TextStyle(
                          color: isLimitReached ? Colors.red : null,
                          fontWeight:
                              isLimitReached ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    DataCell(Text(entry['barcode'] ?? '')),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteEntry(entry['id']),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            icon: const Icon(Icons.edit),
            label: const Text('Edit Stock'),
            onPressed: () => openEditScreen(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
