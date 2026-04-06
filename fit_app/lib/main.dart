import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);

  await Supabase.initialize(
    url: 'https://kladscbmsccbitizibgu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtsYWRzY2Jtc2NjYml0aXppYmd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDY4NDAsImV4cCI6MjA5MDg4Mjg0MH0.GcybiIuggWcT66kwMY-ToTqRgpfHGojEDlZtw3eiR-c',
  );

  runApp(const FitApp());
}

class FitApp extends StatelessWidget {
  const FitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Gym App',
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}
