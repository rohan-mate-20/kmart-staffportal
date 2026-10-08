import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend once at app startup
  await SupabaseService.initialize();

  runApp(const KmartStaffApp());
}

class KmartStaffApp extends StatelessWidget {
  const KmartStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kmart Staff Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
