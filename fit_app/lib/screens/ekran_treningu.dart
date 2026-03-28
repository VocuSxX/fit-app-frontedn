import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EkranTreningu extends StatefulWidget {
  final int treningId;

  const EkranTreningu({super.key, required this.treningId});

  @override
  State<EkranTreningu> createState() => _EkranTreninguState();
}

class _EkranTreninguState extends State<EkranTreningu> {
  bool laduje = true; // Flaga ładowania
  Map<String, dynamic>? szablonDucha; // Zapis JSON-a od Pythona

  @override
  void initState() {
    super.initState();
    pobierzDucha(); // Pobieranie od razu po wejściu na ekran!
  }

  Future<void> pobierzDucha() async {
    debugPrint("Wywołuję Ducha z zaświatów...");
    // Na razie na sztywno prosimy o plan nr 1
    final url = Uri.parse(
      'http://127.0.0.1:8000/szablon_treningu/1?obecny_trening_id=${widget.treningId}',
    );

    try {
      final odpowiedz = await http.get(url);

      if (odpowiedz.statusCode == 200) {
        setState(() {
          szablonDucha = jsonDecode(utf8.decode(odpowiedz.bodyBytes));
          laduje = false;
        });
        debugPrint("Duch pobrany!");
      }
    } catch (e) {
      debugPrint("Błąd połączenia z zaświatami: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trening w toku',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: laduje
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            )
          : budujListeDuchow(),
    );
  }

  // Funkcja budująca widok z danych od Pythona
  Widget budujListeDuchow() {
    // Jeśli z backendu przyszło nic
    if (szablonDucha!['cwiczenia'].isEmpty) {
      return Center(
        child: Text(
          szablonDucha!['wiadomosc'] ?? 'Zacznij swoje pierwsze ćwiczenie!',
          style: const TextStyle(fontSize: 18, color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    final listaCwiczen = szablonDucha!['cwiczenia'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listaCwiczen.length,
      itemBuilder: (context, index) {
        final cwiczenie = listaCwiczen[index];
        final poprzednieSerie = cwiczenie['poprzednie_serie'];
        final notatka = cwiczenie['notatka'];

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nazwa Ćwiczenia
                Text(
                  cwiczenie['nazwa'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Notatka - pokaż tylko jeśli istnieje
                if (notatka != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.yellow[800]?.withOpacity(0.2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notatka,
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                const Text(
                  "Poprzednie wyniki:",
                  style: TextStyle(color: Colors.white54),
                ),

                // Lista serii
                ...poprzednieSerie.map<Widget>((seria) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "• ${seria['waga']} kg  x  ${seria['powtorzenia']} powt. (${seria['typ_serii']})",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
