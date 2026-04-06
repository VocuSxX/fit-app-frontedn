import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class SummaryScreen extends StatefulWidget {
  final int workoutId;
  final String duration;

  const SummaryScreen({
    super.key,
    required this.workoutId,
    required this.duration,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool isLoading = true;
  Map<String, dynamic>? workoutData;

  final user = Supabase.instance.client.auth.currentUser;

  Map<String, String> get authHeaders {
    return {"Content-Type": "application/json", "x-user-id": user?.id ?? ""};
  }

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    final url = Uri.parse('http://127.0.0.1:8000/workouts/${widget.workoutId}');
    try {
      final response = await http.get(url, headers: authHeaders);
      if (response.statusCode == 200) {
        setState(() {
          workoutData = jsonDecode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );

    final sets = workoutData!['sets'] as List;
    final notes = workoutData!['notes'] as List;

    // grupowanie ćwiczeń, serii i notatek
    Map<int, Map<String, dynamic>> groupedExercises = {};

    for (var s in sets) {
      int exId = s['exercise_id'];
      if (!groupedExercises.containsKey(exId)) {
        groupedExercises[exId] = {
          'name': s['exercise'] != null
              ? s['exercise']['name']
              : 'Unknown Exercise',
          'sets': [],
          'note': null,
        };
      }
      groupedExercises[exId]!['sets'].add(s);
    }

    // Przypis notatki do ćwiczeń
    for (var n in notes) {
      int exId = n['exercise_id'];
      if (groupedExercises.containsKey(exId)) {
        groupedExercises[exId]!['note'] = n['content'];
      }
    }

    int exerciseCount = groupedExercises.keys.length;
    int setsCount = sets.length;
    String dateStr = workoutData!['date'] ?? 'Unknown Date';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Workout Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Date: $dateStr",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("Time", widget.duration, Icons.timer),
                        _buildStat(
                          "Exercises",
                          "$exerciseCount",
                          Icons.fitness_center,
                        ),
                        _buildStat(
                          "Sets",
                          "$setsCount",
                          Icons.format_list_numbered,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Completed Exercises:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...groupedExercises.values.map((exData) {
              return Card(
                color: Colors.black26,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NAZWA ĆWICZENIA
                      Text(
                        exData['name'],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // NOTATKA
                      if (exData['note'] != null &&
                          exData['note'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.edit_note,
                                color: Colors.yellow,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exData['note'],
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Divider(color: Colors.white12),

                      // SERIE
                      ...exData['sets'].map(
                        (s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            "• ${s['weight']} kg x ${s['reps']} reps",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CLOSE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
