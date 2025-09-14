import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class ManageSubcategoriesScreen extends StatefulWidget {

  final String moduleName;

  const ManageSubcategoriesScreen({
    super.key,
   
    required this.moduleName,
  });

  @override
  State<ManageSubcategoriesScreen> createState() => _ManageSubcategoriesScreenState();
}

class _ManageSubcategoriesScreenState extends State<ManageSubcategoriesScreen> {
  final TextEditingController _subcategoryController = TextEditingController();
  List<Map<String, dynamic>> _subcategories = [];

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    final result = await DatabaseHelper.instance.getSubcategoriesForModule(widget.moduleName);
    setState(() => _subcategories = result);
  }

  Future<void> _addSubcategory() async {
    final name = _subcategoryController.text.trim();
    if (name.isEmpty) return;

    final subcat = {
      'name': name,
      'module_name': widget.moduleName,
    };

    await DatabaseHelper.instance.insertSubcategory(subcat);
    _subcategoryController.clear();
    await _loadSubcategories();
  }

  Future<void> _deleteSubcategory(String name) async {
    await DatabaseHelper.instance.deleteSubcategory(name);
    await _loadSubcategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subcategories for ${widget.moduleName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _subcategoryController,
              decoration: InputDecoration(
                labelText: 'New Subcategory',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addSubcategory,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _subcategories.length,
                itemBuilder: (context, index) {
                  final subcat = _subcategories[index];
                  return ListTile(
                    title: Text(subcat['name']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSubcategory(subcat['name']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
