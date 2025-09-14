import 'dart:convert';
import 'dart:io';
import 'package:diraj_store/models/DatabaseHelper.dart';

import 'package:permission_handler/permission_handler.dart';


class BackupHelper {
  static const String backupFileName = 'stock_backup.json';


  static Future<File> exportToDownloads() async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      throw Exception("Storage permission denied");
    }

    final List<Map<String, dynamic>> entries =
        await DatabaseHelper.instance.getAllEntries();
    final String jsonString = jsonEncode(entries);

    final Directory downloadsDir = Directory('/storage/emulated/0/Download');
    final File file = File('${downloadsDir.path}/$backupFileName');

    return await file.writeAsString(jsonString);
  }

  ///  Automatically import stock data from Downloads folder on app launch
  static Future<void> autoImportFromDownloads() async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      print(" Storage permission denied");
      return;
    }

    final Directory downloadsDir = Directory('/storage/emulated/0/Download');
    final File file = File('${downloadsDir.path}/$backupFileName');

    if (!file.existsSync()) {
      print(' No backup file found in Downloads.');
      return;
    }

    final String jsonString = await file.readAsString();
    final List<dynamic> decoded = jsonDecode(jsonString);
    final List<Map<String, dynamic>> parsed =
        decoded.map((e) => Map<String, dynamic>.from(e)).toList();

    await DatabaseHelper.instance.importFromJson(parsed);
    print('✅ Stock data restored from backup');
  }


  static Future<void> importFromDownloads() async {
    await autoImportFromDownloads(); 
  }
}
