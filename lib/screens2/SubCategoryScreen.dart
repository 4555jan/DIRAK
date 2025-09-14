import 'package:diraj_store/screen/subcat.dart';
import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:flutter/material.dart';


class SubCategoryScreen extends StatefulWidget {
  final String title;
  final String category;
  final List<String> subCategories;

  const SubCategoryScreen({
    super.key,
    required this.title,
    required this.subCategories,
    required this.category,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<String> _subCategories = [];

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    final data = await DatabaseHelper.instance.getSubcategoriesForModule(widget.title);
    setState(() {
      _subCategories = data.map((e) => e['name'].toString()).toList();
    });
  }

  Future<void> _addSubcategoryDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Subcategory"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter subcategory name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await DatabaseHelper.instance.insertSubcategory({
                  'name': name,
                  'module_name': widget.title,
                });
                Navigator.pop(context);
                await _loadSubcategories();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 208, 230, 248),
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Subcategory"),
        onPressed: _addSubcategoryDialog,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search ${widget.title}...',
                hintStyle: const TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _subCategories = _subCategories
                      .where((sub) =>
                          sub.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _subCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 7 / 2,
                ),
                itemBuilder: (context, index) {
                  final subName = _subCategories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Subcat(
                            title: subName,
                            category: widget.title,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Center(
                        child: Text(
                          subName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
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
