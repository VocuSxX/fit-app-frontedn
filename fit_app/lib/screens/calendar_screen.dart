import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'summary_screen.dart';

class CalendarScreen extends StatelessWidget {
  final List<dynamic> workoutHistory;
  final List<dynamic> plansList;
  final Color Function(int) colorFunction;

  const CalendarScreen({
    super.key,
    required this.workoutHistory,
    required this.plansList,
    required this.colorFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Workout History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 12,
        itemBuilder: (context, index) {
          DateTime monthDate = DateTime(
            DateTime.now().year,
            DateTime.now().month - index,
            1,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(monthDate).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              MonthGrid(
                month: monthDate,
                workoutHistory: workoutHistory,
                plansList: plansList,
                colorFunction: colorFunction,
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final List<dynamic> workoutHistory;
  final List<dynamic> plansList;
  final Color Function(int) colorFunction;

  const MonthGrid({
    super.key,
    required this.month,
    required this.workoutHistory,
    required this.plansList,
    required this.colorFunction,
  });

  void openWorkout(BuildContext context, Map<String, dynamic> workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SummaryScreen(workoutId: workout['id'], duration: "Completed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int firstWeekday = DateTime(month.year, month.month, 1).weekday;

    List<Widget> daySquares = [];
    final today = DateTime.now();

    for (int i = 1; i < firstWeekday; i++) {
      daySquares.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(month.year, month.month, day);
      String dateStr = DateFormat('dd.MM.yyyy').format(currentDate);

      var workoutsOnDay = workoutHistory
          .where((t) => t['data'] == dateStr)
          .toList();
      bool isToday =
          today.day == currentDate.day &&
          today.month == currentDate.month &&
          today.year == currentDate.year;

      daySquares.add(
        GestureDetector(
          onTap: () {
            if (workoutsOnDay.isEmpty) return;

            if (workoutsOnDay.length == 1) {
              openWorkout(context, workoutsOnDay.first);
            } else {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.grey[900],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Workouts on: $dateStr",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...workoutsOnDay.map((t) {
                          String planName = "Unknown plan";
                          try {
                            planName = plansList.firstWhere(
                              (p) => p['id'] == t['plan_id'],
                            )['name'];
                          } catch (_) {}
                          return ListTile(
                            leading: Icon(
                              Icons.fitness_center,
                              color: colorFunction(t['plan_id']),
                            ),
                            title: Text(
                              planName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white54,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              openWorkout(context, t);
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: workoutsOnDay.isNotEmpty || isToday
                        ? Colors.white
                        : Colors.white54,
                    fontWeight: workoutsOnDay.isNotEmpty
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (workoutsOnDay.isNotEmpty) const SizedBox(height: 2),
                if (workoutsOnDay.isNotEmpty)
                  Wrap(
                    spacing: 2,
                    children: workoutsOnDay
                        .map(
                          (t) => Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorFunction(t['plan_id']),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
              .map(
                (d) => Text(
                  d,
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: daySquares,
        ),
      ],
    );
  }
}
