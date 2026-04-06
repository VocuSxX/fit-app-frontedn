import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'summary_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int workoutId;
  final int planId;

  const WorkoutScreen({
    super.key,
    required this.workoutId,
    required this.planId,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool isLoading = true;
  Map<String, dynamic>? ghostTemplate;
  Set<String> completedSets = {};

  Map<String, String> currentWeights = {};
  Map<String, String> currentReps = {};
  Map<int, String> currentNotes = {};
  DateTime startTime = DateTime.now();

  Timer? countdownTimer;
  int totalTime = 120;
  int timeRemaining = 0;
  bool showX = false;
  DateTime? breakEndTime;

  final user = Supabase.instance.client.auth.currentUser;

  Map<String, String> get authHeaders {
    return {"Content-Type": "application/json", "x-user-id": user?.id ?? ""};
  }

  @override
  void initState() {
    super.initState();
    fetchGhost();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startTimer(int seconds) {
    countdownTimer?.cancel();
    setState(() {
      totalTime = seconds;
      timeRemaining = seconds;
      showX = false;
      breakEndTime = DateTime.now().add(Duration(seconds: seconds));
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (breakEndTime == null) {
        timer.cancel();
        return;
      }
      final remaining = breakEndTime!.difference(DateTime.now()).inSeconds;
      setState(() {
        if (remaining > 0) {
          timeRemaining = remaining;
        } else {
          timeRemaining = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> fetchGhost() async {
    final url = Uri.parse(
      'https://vfa-tyx7.onrender.com/workout_template/${widget.planId}?current_workout_id=${widget.workoutId}',
    );
    try {
      final response = await http.get(url, headers: authHeaders);
      if (response.statusCode == 200) {
        setState(() {
          ghostTemplate = jsonDecode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> saveSetToDB(String setKey, int exerciseId, var ghostSet) async {
    double weight =
        double.tryParse(currentWeights[setKey] ?? '') ??
        ghostSet['waga'].toDouble();
    int reps =
        int.tryParse(currentReps[setKey] ?? '') ??
        ghostSet['powtorzenia'].toInt();

    final url = Uri.parse('https://vfa-tyx7.onrender.com/sets');
    try {
      await http.post(
        url,
        headers: authHeaders,
        body: jsonEncode({
          "weight": weight,
          "reps": reps,
          "workout_id": widget.workoutId,
          "exercise_id": exerciseId,
          "set_type": "Working",
        }),
      );
    } catch (e) {
      debugPrint("HTTP Error: $e");
    }
  }

  Future<void> saveNoteToDB(int exerciseId, String noteText) async {
    final url = Uri.parse('https://vfa-tyx7.onrender.com/notes');
    try {
      await http.post(
        url,
        headers: authHeaders,
        body: jsonEncode({
          "content": noteText,
          "workout_id": widget.workoutId,
          "exercise_id": exerciseId,
        }),
      );
    } catch (e) {
      debugPrint("Note error: $e");
    }
  }

  Future<bool> showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Abort Workout?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "If you leave now, some progress may not be saved. Are you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Stay", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Abort", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final exit = await showExitDialog();
        if (exit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Workout in Progress',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
            : buildGhostList(),
        bottomNavigationBar: Container(
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTimer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text(
                            "Finish Workout?",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            "Your completed sets will be saved to history.",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "Keep working out",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent[700],
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Finish & Save",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        for (var entry in currentNotes.entries) {
                          if (entry.value.trim().isNotEmpty) {
                            await saveNoteToDB(entry.key, entry.value.trim());
                          }
                        }

                        final diff = DateTime.now().difference(startTime);
                        String timeFormat =
                            "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SummaryScreen(
                              workoutId: widget.workoutId,
                              duration: timeFormat,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'FINISH WORKOUT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTimer() {
    if (timeRemaining <= 0) return const SizedBox.shrink();
    double progress = timeRemaining / totalTime;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (!showX)
            showX = true;
          else {
            countdownTimer?.cancel();
            timeRemaining = 0;
            breakEndTime = null;
            showX = false;
          }
        });
      },
      child: Container(
        height: 40,
        width: double.infinity,
        color: Colors.grey[900],
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                color: showX
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.greenAccent.withOpacity(0.3),
              ),
            ),
            Center(
              child: showX
                  ? const Icon(Icons.close, color: Colors.white, size: 24)
                  : Text(
                      "Rest: ${timeRemaining ~/ 60}:${(timeRemaining % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGhostList() {
    if (ghostTemplate!['cwiczenia'].isEmpty)
      return Center(
        child: Text(
          ghostTemplate!['wiadomosc'] ?? 'Start your first exercise!',
          style: const TextStyle(fontSize: 18, color: Colors.white54),
        ),
      );
    final exercisesList = ghostTemplate!['cwiczenia'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercisesList.length,
      itemBuilder: (context, index) {
        final exercise = exercisesList[index];
        final exId = exercise['cwiczenie_id'];
        final previousSets = exercise['poprzednie_serie'];
        final restTime = exercise['czas_przerwy'] ?? 120;

        final previousNote = exercise['notatka'];

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise['nazwa'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                if (previousNote != null && previousNote.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.history_edu,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Last time: $previousNote",
                            style: const TextStyle(
                              color: Colors.amber,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextField(
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Add a note for today...",
                    hintStyle: TextStyle(
                      color: Colors.white30,
                      fontStyle: FontStyle.normal,
                    ),
                    icon: Icon(
                      Icons.edit_note,
                      color: Colors.white30,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (text) => currentNotes[exId] = text,
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        "Set",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "KG",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Reps",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Icon(Icons.check, color: Colors.white54, size: 16),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, thickness: 1),
                ...previousSets.asMap().entries.map<Widget>((entry) {
                  int setIndex = entry.key + 1;
                  var ghostSet = entry.value;
                  String setKey = "${exId}_$setIndex";
                  bool isDone = completedSets.contains(setKey);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            '$setIndex',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: '${ghostSet['waga']}',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.black26,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => currentWeights[setKey] = val,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: '${ghostSet['powtorzenia']}',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.black26,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => currentReps[setKey] = val,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: isDone ? Colors.greenAccent : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () {
                              if (!isDone) {
                                setState(() => completedSets.add(setKey));
                                saveSetToDB(setKey, exId, ghostSet);
                                startTimer(restTime);
                              }
                            },
                          ),
                        ),
                      ],
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
