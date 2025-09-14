import 'package:diraj_store/main.dart';
import 'package:diraj_store/screens2/dashboard.dart';
import 'package:diraj_store/models/supabase_sync_helper.dart';
import 'package:flutter/material.dart';

class SplashScreenWrapper extends StatefulWidget {
  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      SupabaseHelper.instance.pauseListener();
      SupabaseHelper.instance.syncBothWays();
      SupabaseHelper.instance.resumeListener();

      SupabaseHelper.instance.initRealtimeListener(
        onDataChanged: () {
          print("global listener triggered!");
        },
        context: navigatorKey.currentContext!,
      );
    } catch (e) {
      print("error during Supabase sync: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Syncing data, please wait...'),
                  ],
                ),
              )
              : const DashboardScreen(),
    );
  }
}
