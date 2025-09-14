import 'package:diraj_store/screen/subcat.dart';
import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:diraj_store/screens2/ManageSubcategoriesScreen.dart';
import 'package:flutter/material.dart';

class SubCategoryScreen extends StatefulWidget {
  final String title;
  final String category;

  const SubCategoryScreen({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<String> subCategories = [];

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    final data = await DatabaseHelper.instance.getSubcategoriesForModule(widget.title);
    setState(() {
      subCategories = data.map((e) => e['name'].toString()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 208, 230, 248),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () async {
              // Wait for ManageSubcategoriesScreen to return, then refresh
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageSubcategoriesScreen(moduleName: widget.title),
                ),
              );
              await _loadSubcategories(); // Refresh the list
            },
            icon: const Icon(Icons.settings),
          ),
        ],
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
                  subCategories = subCategories
                      .where((sub) =>
                          sub.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: subCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 7 / 2,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Subcat(
                            title: subCategories[index],
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
                          subCategories[index],
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
