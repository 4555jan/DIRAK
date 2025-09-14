

import 'package:diraj_store/screens2/SplashScreenWrapper.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await Supabase.initialize(
    url: 'https://qkpsedwvimrkbcshhiyv.supabase.co', // ← your Project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrcHNlZHd2aW1ya2Jjc2hoaXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4NjI0NjcsImV4cCI6MjA2NzQzODQ2N30.sQcPKHOpC69LlSpMr55szgo4HCPBCS9XDdZdDy0Fxw4', // ← your anonKey
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: SplashScreenWrapper(), // This will handle sync + loading screen
    );
  }
}
