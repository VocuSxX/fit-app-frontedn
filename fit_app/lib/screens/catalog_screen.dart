import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool isLoading = true;
  Map<String, List<dynamic>> categories = {};
  List<dynamic> allExercises = [];

  final user = Supabase.instance.client.auth.currentUser;

  Map<String, String> get authHeaders {
    return {"Content-Type": "application/json", "x-user-id": user?.id ?? ""};
  }

  @override
  void initState() {
    super.initState();
    fetchCatalog();
  }

  Future<void> fetchCatalog() async {
    setState(() => isLoading = true);
    final url = Uri.parse('https://vfa-tyx7.onrender.com/catalog');

    try {
      final response = await http.get(
        url,
        headers: authHeaders,
      ); // <--- NAGŁÓWEK
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        Map<String, List<dynamic>> tempCategories = {};
        List<dynamic> tempAll = [];

        if (decodedData is Map) {
          decodedData.forEach((muscleGroup, list) {
            tempCategories[muscleGroup] = [];
            for (var exercise in list) {
              var newExercise = Map<String, dynamic>.from(exercise);
              newExercise['muscle_group'] = muscleGroup;
              tempCategories[muscleGroup]!.add(newExercise);
              tempAll.add(newExercise);
            }
          });
        }
        setState(() {
          categories = tempCategories;
          allExercises = tempAll;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching catalog: $e");
      setState(() => isLoading = false);
    }
  }

  void openList(
    String title,
    List<dynamic> list, {
    bool showSearch = false,
  }) async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseListScreen(
          title: title,
          exercises: list,
          showSearch: showSearch,
        ),
      ),
    );
    if (selectedExercise != null) {
      if (mounted) Navigator.pop(context, selectedExercise);
    }
  }

  void openAddExercise() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExerciseScreen()),
    );
    if (added == true) fetchCatalog();
  }

  Widget buildTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Select Folder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            )
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                buildTile(
                  "All\nExercises",
                  Icons.search,
                  Colors.blueAccent,
                  () => openList("All", allExercises, showSearch: true),
                ),
                buildTile(
                  "Add Custom\nExercise",
                  Icons.add_circle,
                  Colors.greenAccent,
                  openAddExercise,
                ),
                ...categories.keys.map(
                  (group) => buildTile(
                    group,
                    Icons.fitness_center,
                    Colors.pinkAccent,
                    () => openList(group, categories[group]!),
                  ),
                ),
              ],
            ),
    );
  }
}

class ExerciseListScreen extends StatefulWidget {
  final String title;
  final List<dynamic> exercises;
  final bool showSearch;

  const ExerciseListScreen({
    super.key,
    required this.title,
    required this.exercises,
    this.showSearch = false,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<dynamic> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = widget.exercises;
  }

  void filterList(String query) {
    setState(() {
      filtered = widget.exercises.where((ex) {
        final name = ex['nazwa'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search exercise...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: filterList,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ex = filtered[index];
                return ListTile(
                  title: Text(
                    ex['nazwa'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    ex['muscle_group'] ?? 'No group',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(
                    Icons.add_circle,
                    color: Colors.greenAccent,
                  ),
                  onTap: () => Navigator.pop(context, ex),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController timeController = TextEditingController(
    text: "120",
  );
  String selectedGroup = "Chest";

  final List<String> groups = [
    "Chest",
    "Back",
    "Legs",
    "Shoulders",
    "Biceps",
    "Triceps",
    "Core",
    "Full body",
    "Other",
  ];
  bool isSaving = false;

  final user = Supabase.instance.client.auth.currentUser;

  Map<String, String> get authHeaders {
    return {"Content-Type": "application/json", "x-user-id": user?.id ?? ""};
  }

  Future<void> saveExercise() async {
    if (nameController.text.isEmpty) return;
    setState(() => isSaving = true);

    final url = Uri.parse('https://vfa-tyx7.onrender.com/exercises');
    try {
      final response = await http.post(
        url,
        headers: authHeaders,
        body: jsonEncode({
          "name": nameController.text,
          "muscle_group": selectedGroup,
          "default_rest_time": int.tryParse(timeController.text) ?? 120,
        }),
      );
      if (response.statusCode == 200 && mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'New Exercise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.greenAccent[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Exercise Name",
              style: TextStyle(color: Colors.white54),
            ),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: "e.g. Bench Press",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Muscle Group", style: TextStyle(color: Colors.white54)),
            DropdownButton<String>(
              value: selectedGroup,
              dropdownColor: Colors.grey[900],
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              items: groups
                  .map(
                    (String p) =>
                        DropdownMenuItem<String>(value: p, child: Text(p)),
                  )
                  .toList(),
              onChanged: (String? newGroup) {
                if (newGroup != null) setState(() => selectedGroup = newGroup);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Default Rest Time (seconds)",
              style: TextStyle(color: Colors.white54),
            ),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: isSaving ? null : saveExercise,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SAVE TO DATABASE',
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
