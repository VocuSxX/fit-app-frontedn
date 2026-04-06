import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_screen.dart';
import 'create_plan_screen.dart';
import 'calendar_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoading = true;
  bool isPreviewLoading = false;
  List<dynamic> plansList = [];
  List<dynamic> workoutHistory = [];
  List<dynamic> previewExercises = [];
  int? selectedPlanId;

  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Map<String, String> get authHeaders {
    return {"Content-Type": "application/json", "x-user-id": user?.id ?? ""};
  }

  Future<void> fetchData() async {
    if (user == null) return;
    await fetchPlans();
    await fetchHistory();
    if (selectedPlanId != null) {
      await fetchPlanPreview(selectedPlanId!);
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchPlans() async {
    final url = Uri.parse('https://vfa-tyx7.onrender.com/plans');
    try {
      final response = await http.get(url, headers: authHeaders);
      if (response.statusCode == 200) {
        plansList = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        if (plansList.isNotEmpty) {
          if (selectedPlanId == null ||
              !plansList.any((p) => p['id'] == selectedPlanId)) {
            selectedPlanId = plansList.first['id'];
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching plans: $e");
    }
  }

  Future<void> fetchPlanPreview(int planId) async {
    setState(() => isPreviewLoading = true);
    final url = Uri.parse(
      'https://vfa-tyx7.onrender.com/workout_template/$planId',
    );
    try {
      final response = await http.get(url, headers: authHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          previewExercises = data['cwiczenia'] ?? [];
          isPreviewLoading = false;
        });
      }
    } catch (e) {
      setState(() => isPreviewLoading = false);
    }
  }

  Future<void> fetchHistory() async {
    final url = Uri.parse('https://vfa-tyx7.onrender.com/history');
    try {
      final response = await http.get(url, headers: authHeaders);
      if (response.statusCode == 200) {
        workoutHistory = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  Future<void> startWorkout() async {
    if (selectedPlanId == null) return;
    String today = DateFormat('dd.MM.yyyy').format(DateTime.now());

    final url = Uri.parse('https://vfa-tyx7.onrender.com/workouts');
    try {
      final response = await http.post(
        url,
        headers: authHeaders,
        body: jsonEncode({"date": today, "plan_id": selectedPlanId}),
      );

      if (response.statusCode == 200) {
        final newWorkout = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutScreen(
                workoutId: newWorkout['id'],
                planId: selectedPlanId!,
              ),
            ),
          );
          fetchData();
        }
      }
    } catch (e) {
      debugPrint("Error starting workout: $e");
    }
  }

  Color assignColor(int planId) {
    final colors = [
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
    ];
    return colors[(planId) % colors.length];
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'My Gym',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(
                      workoutHistory: workoutHistory,
                      plansList: plansList,
                      colorFunction: assignColor,
                    ),
                  ),
                );
              },
              child: Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'MMMM yyyy',
                            ).format(DateTime.now()).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.open_in_full,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MonthGrid(
                        month: DateTime.now(),
                        workoutHistory: workoutHistory,
                        plansList: plansList,
                        colorFunction: assignColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedPlanId,
                  dropdownColor: const Color(0xFF1E1E1E),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.pinkAccent,
                  ),
                  isExpanded: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  items: [
                    ...plansList.map(
                      (plan) => DropdownMenuItem<int?>(
                        value: plan['id'],
                        child: Text(plan['name']),
                      ),
                    ),
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        "+ Create new plan",
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val == null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePlanScreen(),
                        ),
                      );
                      fetchData();
                    } else {
                      setState(() => selectedPlanId = val);
                      fetchPlanPreview(val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TODAY's EXERCISES:",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isPreviewLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.pinkAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : previewExercises.isEmpty
                          ? const Text(
                              "No exercises in this plan. Add something!",
                              style: TextStyle(color: Colors.white30),
                            )
                          : ListView.builder(
                              itemCount: previewExercises.length,
                              itemBuilder: (context, index) {
                                final ex = previewExercises[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white24,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          ex['nazwa'] ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedPlanId != null
                ? Colors.pinkAccent
                : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: selectedPlanId != null ? startWorkout : null,
          child: const Text(
            'START WORKOUT ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
