import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:flutter/material.dart';


class ManageModulesScreen extends StatefulWidget {
  const ManageModulesScreen({super.key});

  @override
  State<ManageModulesScreen> createState() => _ManageModulesScreenState();
}

class _ManageModulesScreenState extends State<ManageModulesScreen> {
  List<Map<String, dynamic>> modules = [];

  @override
  void initState() {
    super.initState();
    loadModules();
  }

  Future<void> loadModules() async {
    modules = await DatabaseHelper.instance.getAllModules();
    setState(() {});
  }

  Future<void> addOrEditModule({Map<String, dynamic>? module}) async {
    final nameController = TextEditingController(text: module?['name'] ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(module == null ? 'Add Module' : 'Edit Module'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Module Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newModule = {
        'name': result,
        'is_default': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (module == null) {
        await DatabaseHelper.instance.insertModule(newModule);
      } else {
        await DatabaseHelper.instance.updateModule(module['id'], newModule);
      }

      await loadModules();
    }
  }

  Future<void> confirmDeleteModule(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Module'),
        content: const Text('Are you sure you want to delete this module?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteModule(id);
      await loadModules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Modules')),
      body: ListView.builder(
        itemCount: modules.length,
        itemBuilder: (_, index) {
          final module = modules[index];
          final isDefault = module['is_default'] == 1;

          return ListTile(
            title: Text(module['name']),
            subtitle: isDefault
                ? const Text('Default', style: TextStyle(color: Colors.grey))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: isDefault ? null : () => addOrEditModule(module: module),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: isDefault ? null : () => confirmDeleteModule(module['id']),
                ),
              
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditModule(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
