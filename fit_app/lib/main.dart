import 'package:flutter/material.dart';

// Importujemy Główny ekran
import 'screens/ekran_glowny.dart';

void main() {
  runApp(const FitApp());
}

class FitApp extends StatelessWidget {
  const FitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moja Apka Treningowa',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.pinkAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const EkranGlowny(), //Ładujemy ekran startowy
    );
  }
}
