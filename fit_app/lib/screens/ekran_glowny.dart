import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'ekran_treningu.dart';

// ==========================================
// ERAN GŁÓWNY
// ==========================================
class EkranGlowny extends StatelessWidget {
  const EkranGlowny({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wybierz Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF2196F3),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Trening A',
              style: TextStyle(fontSize: 22, color: Colors.white70),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                debugPrint("Wysyłam sygnał do bazy...");

                final url = Uri.parse('http://127.0.0.1:8000/treningi');
                final paczka = jsonEncode({"data": "27.03.2026", "plan_id": 1});

                try {
                  final odpowiedz = await http.post(
                    url,
                    headers: {"Content-Type": "application/json"},
                    body: paczka,
                  );

                  if (odpowiedz.statusCode == 200) {
                    final odpowiedzJson = jsonDecode(odpowiedz.body);
                    final noweId = odpowiedzJson['id'];

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EkranTreningu(treningId: noweId),
                        ),
                      );
                    }
                  } else {
                    debugPrint("BŁĄD BRAMKARZA: ${odpowiedz.statusCode}");
                  }
                } catch (e) {
                  debugPrint("BŁĄD POŁĄCZENIA: $e");
                }
              },
              child: const Text(
                'ZACZYNAMY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
