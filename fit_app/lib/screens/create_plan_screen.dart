import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'catalog_screen.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final TextEditingController nameController = TextEditingController();
  List<Map<String, dynamic>> selectedExercises = [];
  bool isSaving = false;

  final user = Supabase.instance.client.auth.currentUser;

  Map<String, String> get authHeaders {
    return {"Content-Type": "application/json", "x-user-id": user?.id ?? ""};
  }

  void addFromCatalog() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CatalogScreen()),
    );
    if (selected != null) {
      setState(() {
        selectedExercises.add({"exercise": selected, "sets": 3, "reps": 10});
      });
    }
  }

  Future<void> savePlan() async {
    if (nameController.text.isEmpty || selectedExercises.isEmpty) return;
    setState(() => isSaving = true);

    try {
      // Zapis Planu
      final resPlan = await http.post(
        Uri.parse('https://vfa-tyx7.onrender.com/plans'),
        headers: authHeaders,
        body: jsonEncode({"name": nameController.text}),
      );
      final planData = jsonDecode(utf8.decode(resPlan.bodyBytes));
      final planId = planData['id'];

      // Zapis Treningu
      final resWorkout = await http.post(
        Uri.parse('https://vfa-tyx7.onrender.com/workouts'),
        headers: authHeaders,
        body: jsonEncode({"date": "TEMPLATE", "plan_id": planId}),
      );
      final workoutData = jsonDecode(utf8.decode(resWorkout.bodyBytes));
      final workoutId = workoutData['id'];

      // Zapis Serii
      for (var item in selectedExercises) {
        int exId = item['exercise']['id'];
        int setsCount = item['sets'];
        int reps = item['reps'];

        for (int i = 0; i < setsCount; i++) {
          await http.post(
            Uri.parse('https://vfa-tyx7.onrender.com/sets'),
            headers: authHeaders,
            body: jsonEncode({
              "weight": 0,
              "reps": reps,
              "workout_id": workoutId,
              "exercise_id": exId,
              "set_type": "Working",
            }),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error saving plan: $e");
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Plan Creator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Plan Name (e.g. Push Day)",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: selectedExercises.length,
                itemBuilder: (context, index) {
                  final item = selectedExercises[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['exercise']['nazwa'],
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => setState(
                                  () => selectedExercises.removeAt(index),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    "Sets",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => setState(
                                          () => item['sets'] = (item['sets'] > 1
                                              ? item['sets'] - 1
                                              : 1),
                                        ),
                                      ),
                                      Text(
                                        "${item['sets']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            setState(() => item['sets']++),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    "Target Reps",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => setState(
                                          () => item['reps'] = (item['reps'] > 1
                                              ? item['reps'] - 1
                                              : 1),
                                        ),
                                      ),
                                      Text(
                                        "${item['reps']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            setState(() => item['reps']++),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add, color: Colors.greenAccent),
              label: const Text(
                "ADD EXERCISE",
                style: TextStyle(color: Colors.greenAccent),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                side: const BorderSide(color: Colors.greenAccent),
              ),
              onPressed: addFromCatalog,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedExercises.isNotEmpty &&
                          nameController.text.isNotEmpty
                      ? Colors.pinkAccent
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: isSaving ? null : savePlan,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SAVE PLAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
