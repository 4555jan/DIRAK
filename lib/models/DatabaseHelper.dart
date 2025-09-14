import 'dart:convert';
import 'dart:io';
import 'package:diraj_store/models/supabase_sync_helper.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stocks.db');

    return await openDatabase(
      path,
      version: 4, 
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE stocks (
            id INTEGER PRIMARY KEY,
            name TEXT,
            size TEXT,
            stockIn INTEGER,
            stockOut INTEGER,
            stock INTEGER,
            totalStock INTEGER,
            totalstockhit INTEGER,
            barcode TEXT,
            category TEXT,
            subcategory TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE modules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            is_default INTEGER NOT NULL DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE subcategories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            module_name TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (module_name) REFERENCES modules(name) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE stocks ADD COLUMN created_at TEXT;");
          await db.execute("ALTER TABLE stocks ADD COLUMN updated_at TEXT;");
          await db.execute("ALTER TABLE stocks ADD COLUMN stock INTEGER DEFAULT 0;");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE stocks ADD COLUMN totalstockhit INTEGER DEFAULT 0;");
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS modules (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              is_default INTEGER NOT NULL DEFAULT 1,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS subcategories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              module_name TEXT NOT NULL,
              is_default INTEGER NOT NULL DEFAULT 1,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (module_name) REFERENCES modules(name) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<int> insertModule(Map<String, dynamic> module, {bool skipRemoteSync = false}) async {
    final db = await database;
    module['created_at'] ??= DateTime.now().toIso8601String();
    final cleaned = Map<String, dynamic>.from(module);
if (cleaned['is_default'] is bool) {
  cleaned['is_default'] = cleaned['is_default'] ? 1 : 0;
}
int id = await db.insert(
  'modules',
  cleaned,
  conflictAlgorithm: ConflictAlgorithm.replace,
);
    if (!skipRemoteSync) {
      try {
        await SupabaseHelper.instance.insertOrUpdateRemoteModule(module);
      } catch (e) {
        print('Supabase insert module failed: $e');
      }
    }

    return id;
  }
// insert the module to supabase 
  Future<int> updateModule(String oldName, Map<String, dynamic> updatedFields,
      {bool skipRemoteSync = false}) async {
    final db = await database;

    final result = await db.update(
      'modules',
      updatedFields,
      where: 'name = ?',
      whereArgs: [oldName],
    );

    if (!skipRemoteSync) {
      try {
        await SupabaseHelper.instance.insertOrUpdateRemoteModule(updatedFields);
      } catch (e) {
        print('$e');
      }
    }

    return result;
  }//update the module to supabase 

  Future<int> deleteModule(int id, {bool skipRemoteSync = false}) async {
    final db = await database;

    final List<Map<String, dynamic>> result =
        await db.query('modules', where: 'id = ?', whereArgs: [id]);

    int deleted = await db.delete('modules', where: 'id = ?', whereArgs: [id]);

    if (!skipRemoteSync && result.isNotEmpty) {
      try {
        await SupabaseHelper.instance.deleteRemoteModule(result.first['name']);
      } catch (e) {
        print("$e");
      }
    }

    return deleted;
  }//delete the module to supabase 

  Future<List<Map<String, dynamic>>> getAllModules() async {
    final db = await database;
    return await db.query('modules');
  }

  Future<int> insertSubcategory(Map<String, dynamic> subcat, {bool skipRemoteSync = false}) async {
  final db = await database;
  subcat['created_at'] ??= DateTime.now().toIso8601String();
  final cleaned = Map<String, dynamic>.from(subcat);
if (cleaned['is_default'] is bool) {
  cleaned['is_default'] = cleaned['is_default'] ? 1 : 0;
}

  int id = await db.insert(
    'subcategories',
    cleaned,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  if (!skipRemoteSync) {
    try {
      await SupabaseHelper.instance.insertOrUpdateRemoteSubcategory(subcat);
    } catch (e) {
      print('Supabase insert subcategory failed: $e');
    }
  }

  return id;
}

Future<Map<String, List<String>>> getAllSubcategoriesGroupedByModule() async {
  final db = await database;
  final result = await db.query('subcategories');

  final map = <String, List<String>>{};
  for (final row in result) {
    final module = row['module_name'] as String;
    final name = row['name'] as String;

    if (!map.containsKey(module)) {
      map[module] = [];
    }
    map[module]!.add(name);
  }
  return map;
}


  Future<List<Map<String, dynamic>>> getSubcategories(int moduleId) async {
    final db = await database;
    return await db.query('subcategories');
  }

  Future<List<Map<String, dynamic>>> getSubcategoriesForModule(String moduleName) async {
    final db = await database;
    return await db.query(
      'subcategories',
      where: 'module_name = ?',
      whereArgs: [moduleName],
    );
  }

  Future<int> deleteSubcategory(String name) async {
    final db = await database;
    return await db.delete('subcategories', where: 'name = ?', whereArgs: [name]);
  }

  Future<int> insertEntry(Map<String, dynamic> entry,
      {bool skipRemoteSync = false}) async {
    final db = await database;
    entry['created_at'] ??= DateTime.now().toIso8601String();
    entry['updated_at'] = DateTime.now().toIso8601String();

    int id = await db.insert(
      'stocks',
      entry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (!skipRemoteSync) {
      try {
        await SupabaseHelper.instance.insertOrUpdateRemoteEntry(entry);
      } catch (e) {
        print('❌ Supabase insert failed: $e');
      }
    }

    return id;
  }

  Future<int> updateEntry(Map<String, dynamic> entry,
      {bool skipRemoteSync = false}) async {
    final db = await database;
    entry['updated_at'] = DateTime.now().toIso8601String();

    int count = await db.update(
      'stocks',
      entry,
      where: 'id = ?',
      whereArgs: [entry['id']],
    );

    if (!skipRemoteSync) {
      try {
        await SupabaseHelper.instance.insertOrUpdateRemoteEntry(entry);
      } catch (e) {
        print('❌ Supabase update failed: $e');
      }
    }

    return count;
  }

  Future<int> deleteEntry(int id, {bool skipRemoteSync = false}) async {
    final db = await database;

    if (!skipRemoteSync) {
      try {
        await SupabaseHelper.instance.deleteRemoteEntry(id);
      } catch (e) {
        print("❌ Failed to delete from Supabase: $e");
      }
    }

    return await db.delete('stocks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getEntryByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query(
      'stocks',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getEntryById(int id) async {
    final db = await database;
    final result = await db.query('stocks', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final db = await database;
    return await db.query('stocks');
  }

  Future<List<Map<String, dynamic>>> getEntriesForSubcategory(String subcategory) async {
    final db = await database;
    return await db.query(
      'stocks',
      where: 'subcategory = ?',
      whereArgs: [subcategory],
    );
  }
// from here all the database...... both the database tasks got done all the other 4 funtions below 
// are of import from the json file which we are storeing in the downloads folder of the phone 
//when we click the button from the dashboard it either triggers one of these funtions to either 
//import the local json(converted from the sqlite file which is also in the main machine)
// or export from it for storage purposes and for faster data of transmission and also to make the app slitghtly offline 
//the changes happened to db will reflect in the json if we pressed the button and when the device comes online 
//again those new changes from the db will get pushed to the cloud and from the cloud to other people's devices 
//local db which how exactly the bidirectional syncing works in this software
 
  Future<void> importFromJson(List<Map<String, dynamic>> data) async {
    for (final entry in data) {
      await insertEntry(entry, skipRemoteSync: true);
    }
  }//Loads data from a JSON file  and inserts it into your app's database.

  Future<void> exportToDownloadsJson() async {
    final db = await database;
    final result = await db.query('stocks');
    final jsonStr = jsonEncode(result);

    final path = await _getDownloadPath();
    final file = File('$path/stock_backup.json');
    await file.writeAsString(jsonStr);
  }//Saves your app's current data to a .json

  Future<void> autoImportFromDownloadsJson() async {
    final path = await _getDownloadPath();
    final file = File('$path/stock_backup.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(content);

      for (var entry in jsonData) {
        await insertEntry(
          Map<String, dynamic>.from(entry),
          skipRemoteSync: true,
        );
      }
    }
  }//Automatically restore stock data from backup

  Future<String> _getDownloadPath() async {
    final directory = await getDownloadsDirectory();
    return directory?.path ?? (await getExternalStorageDirectory())!.path;
  }
}
