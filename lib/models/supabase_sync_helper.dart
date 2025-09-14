import 'package:diraj_store/main.dart';
import 'package:diraj_store/models/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  static final SupabaseHelper instance = SupabaseHelper._();
  static final _client = Supabase.instance.client;

  SupabaseHelper._();

  void _showSnackBar(BuildContext? context, String message) {
    context ??= navigatorKey.currentContext;

    if (context == null) {
      print("⚠️ Context is null, can't show snackbar");
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final messenger = ScaffoldMessenger.maybeOf(context!);
        if (messenger != null && context.mounted) {
          print("SnackBar shown: $message");
        } else {
          print("No ScaffoldMessenger found or context not mounted");
        }
      } catch (e) {
        print("$e");
      }
    });
  }//snackbar over 

  bool _isListening = true;

  void pauseListener() => _isListening = false;
  void resumeListener() => _isListening = true;

  bool _alreadySubscribed = false;

  void initRealtimeListener({
    required void Function() onDataChanged,
    required BuildContext context,
  }) {
    if (_alreadySubscribed) {
      print(
        "⚠️ Already subscribed to stocks realtime channel. Skipping duplicate.",
      );
      return;
    }

    _alreadySubscribed = true;

    _client
        .channel('public:stocks')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stocks',
          callback: (payload) async {
            final newData = payload.newRecord;
            final oldData = payload.oldRecord;
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
              case PostgresChangeEvent.update:
                final local = await DatabaseHelper.instance.getEntryById(
                  newData['id'],
                );
                final remoteTime = DateTime.tryParse(
                  newData['updated_at'] ?? '',
                );
                final localTime =
                    local != null
                        ? DateTime.tryParse(local['updated_at'] ?? '')
                        : null;

                final shouldUpdate =
                    local == null ||
                    (remoteTime != null &&
                        localTime != null &&
                        remoteTime.isAfter(localTime));

                if (shouldUpdate) {
                  await DatabaseHelper.instance.insertEntry(
                    newData,
                    skipRemoteSync: true,
                  );
                  onDataChanged();
                  _showSnackBar(context, 'Stock updated in real-time');
                }

                break;

              case PostgresChangeEvent.delete:
                final id = oldData['id'];
                await DatabaseHelper.instance.deleteEntry(
                  id,
                  skipRemoteSync: true,
                );
                onDataChanged();
                _showSnackBar(context, 'Stock deleted in real-time ❌');

                break;

              default:
                print("⚠️ Unhandled event type: ${payload.eventType}");
            }
          },
        )
        .subscribe();
  }

  Future<void> insertOrUpdateRemoteModule(Map<String, dynamic> module) async {
    try {
      await _client.from('modules').upsert(module, onConflict: 'name');
    } catch (e) {
      print(e);
    }
  }

  Future<void> uploadModulesToSupabase() async {
    final modules = await DatabaseHelper.instance.getAllModules();
    for (final module in modules) {
      try {
        await insertOrUpdateRemoteModule(module);
      } catch (e) {
        print(" Failed to upload module: ${module['name']}, Error: $e");
      }
    }
    print(" Uploaded all local modules to Supabase");
  }

  Future<void> insertOrUpdateRemoteSubcategory(
    Map<String, dynamic> subcat,
  ) async {
    try {
      await _client
          .from('subcategories')
          .upsert(subcat, onConflict: 'name,module_name'); // Composite key
    } catch (e) {}
  }

  Future<void> deleteRemoteModule(String moduleName) async {
    try {
      await _client.from('modules').delete().eq('name', moduleName);
      print(' Deleted module from Supabase: $moduleName');
    } catch (e) {
      print(" Error deleting module: $e");
    }
  }

  Future<void> insertOrUpdateRemoteEntry(Map<String, dynamic> entry) async {
    try {
      await _client.from('stocks').upsert(entry);
      print('Synced entry to Supabase');
    } catch (e) {
      print('Error syncing entry: $e');
    }
  }

  /// Push all local data to Supabase
  Future<void> uploadToSupabase() async {
    final localEntries = await DatabaseHelper.instance.getAllEntries();
    try {
      for (final entry in localEntries) {
        await _client.from('stocks').upsert(entry);
      }
      print(" Uploaded all local data to Supabase");
    } catch (e) {
      print("$e");
    }
  }

  Future<void> syncFromSupabase() async {
    try {
 
      final List<Map<String, dynamic>> moduleList =
          await _client.from('modules').select();

      for (final module in moduleList) {
        await DatabaseHelper.instance.insertModule(
          module,
          skipRemoteSync: true,
        );
      }//syncin module or general category  basically from supabase to local db

      final List<Map<String, dynamic>> subcatList =
          await _client.from('subcategories').select();

      for (final subcat in subcatList) {
        await DatabaseHelper.instance.insertSubcategory(
          subcat,
          skipRemoteSync: true,
        );
      }//syncin subcategory of basically from supabase to local db

      final List<Map<String, dynamic>> stockList =
          await _client.from('stocks').select();

      for (final entry in stockList) {
        await DatabaseHelper.instance.insertEntry(entry, skipRemoteSync: true);
      }//syncin stock table or entries   basically from supabase to local db

      print(
        " Synced modules, subcategories, and stock from Supabase into SQLite",
      );
    } catch (e) {
      print("$e");
    }
  }

  Future<void> syncBothWays() async {
    await syncFromSupabase();
    await uploadToSupabase();
  }

  Future<void> deleteRemoteEntry(int id) async {
    try {
      await _client.from('stocks').delete().eq('id', id);
      print("Deleted from Supabase: id = $id");
    } catch (e) {
      print("Error deleting from Supabase: $e");
    }
  }
}
