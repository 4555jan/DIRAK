import 'package:diraj_store/screen/BarcodeScannerScreen.dart';
import 'package:diraj_store/screen/multiplees.dart';
import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:diraj_store/models/backup_helper.dart';
import 'package:diraj_store/screens2/managemodeulesscreen.dart';
import 'package:diraj_store/models/supabase_sync_helper.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> modules = [];
  List<String> filteredModules = [];
  Map<String, List<String>> subcategoryMap = {};

  final Map<String, List<String>> defaultSubcategoriesMap = {
    'ncc-items': [
      'wingz green cap',
      'ncc tracksuit',
      'ceremonial item ncc',
      'ncc all item',
    ],
    'scout-items': ['scout and guide all items', 'scout and guide fabric'],
    'shoes': [
      'wildfoot tango tan',
      'wildfoot tango black',
      'wildfoot oscar tan',
      'wildfoot oscar black',
      'wildfoot oxford tan',
      'wildfoot oxford black',
      'wildfoot officer tan',
      'gsf dms',
      'gsf regular cut',
      'gsf derby black heavy',
      'gsf derby tan',
      'sega white shoes',
      'legwork tan',
      'legwork black',
      'sega black',
      'sega brown',
      'gsf white sports shoes',
      'cosmo dms',
    ],
    'summer-cap': ['summer cap'],
    'barret-cap': [
      'soft-touch blue',
      'khakhi barret cap',
      'attack blue',
      'wingz black cap',
      'air wingz preium blue',
    ],
    'tshirt': [
      'cotton t-shirts',
      'dry fit t-shirts',
      'wingz ncc t-shirt blue',
      'wingz ncc t-shirt white',
      'wingz gp logo t-shirt new',
      'wingz gp logo t-shirt old',
      'wingz plain white t-shirt',
      'wingz plain white full sleeve',
      'wingz gp logo full sleeve',
      'wingz gp logo lisu kapad',
      'wingz forest logo t-shirt',
      'javline army t-shirt',
      'wingz trb t-shirt',
      'javline army trackpant',
      'wingz fire t-shirt',
      'vega dt t-shirt',
      'vega dt white',
      'vega black t-shirt',
      'cb black lower',
      'cb blue lower',
      'cb blue ncc lower',
      'vega pt lower',
      'vega white lower',
      'vega dbl lower',
      'trackpant lycra black',
      'cb white lower',
      'vega tracksuit el',
      'camo t-shirt',
      'camo trackpant',
      'cb crown net trackpant blue',
      'cb crown net trackpant black',
      'trackpant lycra blue',
      'wingz khakhi t-shirt',
      'upper grey/black without logo',
      'upper grey/black with logo',
      'upper blue with logo',
    ],
    'security-items': [
      'security t-shirt',
      'security jacket',
      'plain black-tshirt',
      'unknown',
    ],
    'belts': ['leather belt', 'nylon belt'],
    'peak-cap': [
      'peak cap khakhi light',
      'peak cap khakhi dark',
      'peak cap black dark khakhi',
      'peak cap black',
      'peak cap blue',
      'khakhi black peak shd.1',
      'self peak shd.1',
    ],
    'socks': ['cut socks', 'long socks'],
    'uniforms': ['uniforms and safari'],
    'other-items': [
      'colonal jersey',
      'buckle',
      'oswal jersey',
      'colonal jersey patali',
      'items',
      'oswell jersey black',
      'shoulder badge',
      'khakhi jacket full sleeve',
      'khakhi jacket half sleeve',
    ],
    'lanyard': ['lanyard'],
    'khakhi-fabric': ['g-oswal fabric'],
  };

  @override
  void initState() {
    super.initState();

    // Defer loading to after first frame for smoother UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModulesFromDB(); // optimized loading
    });

    Future.microtask(() => _backgroundSync()); // background syncing
  }

  Future<void> _backgroundSync() async {
    try {
      await _ensureModulesInDB();
      SupabaseHelper.instance.uploadToSupabase(); // don’t await
      _ensureSubcategoriesInDB(); // don’t await
      _attemptAutoImport(); // don’t await
    } catch (e) {
      print("🔴 Background sync failed: $e");
    }
  }

  Future<void> _ensureModulesInDB() async {
    final existingModules = await DatabaseHelper.instance.getAllModules();
    final existingNames =
        existingModules.map((m) => m['name'] as String).toSet();
    for (final moduleName in defaultSubcategoriesMap.keys) {
      if (!existingNames.contains(moduleName)) {
        await DatabaseHelper.instance.insertModule({
          'name': moduleName,
          'is_default': 1,
        });
      }
    }
  }

  Future<void> _ensureSubcategoriesInDB() async {
    for (final entry in defaultSubcategoriesMap.entries) {
      final moduleName = entry.key;
      final subcategories = entry.value;

      final existingSubcats =
          await DatabaseHelper.instance.getSubcategoriesForModule(moduleName);
      final existingNames =
          existingSubcats.map((s) => s['name'] as String).toSet();

      for (final sub in subcategories) {
        if (!existingNames.contains(sub)) {
          await DatabaseHelper.instance.insertSubcategory({
            'name': sub,
            'module_name': moduleName,
          });
        }
      }
    }
  }

  Future<void> _attemptAutoImport() async {
    final existing = await DatabaseHelper.instance.getAllEntries();
    if (existing.isEmpty) {
      await BackupHelper.autoImportFromDownloads();
    }
  }

  // ✅ Optimized: Only 2 DB queries instead of 1 per module
 Future<void> _loadModulesFromDB() async {
  final modulesData = await DatabaseHelper.instance.getAllModules();
  final subcategoryMap =
      await DatabaseHelper.instance.getAllSubcategoriesGroupedByModule();

  setState(() {
    modules = modulesData.map((e) => e['name'] as String).toList();
    filteredModules = List.from(modules);
    this.subcategoryMap = subcategoryMap;
  });
}


  void filterModules(String query) {
    setState(() {
      filteredModules = modules
          .where((module) => module.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final file = await BackupHelper.exportToDownloads();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Backup saved to Downloads: ${file.path}')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('❌ Export failed: $e')));
            }
          }
        },
        icon: const Icon(Icons.save_alt),
        label: const Text("Export Backup"),
      ),
      backgroundColor: const Color.fromARGB(255, 175, 213, 245),
      appBar: AppBar(
        title: const Text('Dashboard'),
        toolbarHeight: 90,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Manage Modules',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ManageModulesScreen()),
              ).then((_) => _loadModulesFromDB());
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BarcodeScannerScreen(subcategory: ''),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search modules...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: filterModules,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 7 / 2,
                ),
                itemCount: filteredModules.length,
                itemBuilder: (context, index) {
                  final module = filteredModules[index];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubCategoryScreen(
                            title: module,
                            category: module,
                          ),
                        ),
                      );
                      await _loadModulesFromDB(); // Refresh after return
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Center(
                        child: Text(
                          module,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
