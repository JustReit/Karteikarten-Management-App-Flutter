import 'package:flutter/material.dart';
import 'package:karteikarten_manager/database/databaseHelper.dart';
import 'package:karteikarten_manager/service/functions.dart';
import 'package:karteikarten_manager/service/uiElements.dart';


class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<String> totalAnzahl = Future.value('0');
  late Future<String> totalZeit = Future.value('0');
  late Future<String> totalZeitToday = Future.value('0');
  late Future<String> timePerCardAnschauen = Future.value('0');
  late Future<String> timePerCardDurcharbeiten = Future.value('0');
  late Future<String> maxTimePerDay = Future.value('0');
  late Future<String> maxStackPerDay = Future.value('0');
  late Future<String> avgStackPerDay = Future.value('0');
  late Future<String> avgTimePerDay = Future.value('0');

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    Map<String, dynamic> stats = await DatabaseHelper().getStats();
    setState(() {
      totalAnzahl = Future.value(stats['totalAnzahl']);
      totalZeit = Future.value(stats['totalZeit']);
      totalZeitToday = Future.value(stats['totalZeitToday']);
      avgTimePerDay = Future.value(stats['avgTimePerDay']);
      maxTimePerDay = Future.value(stats['maxTimePerDay']);
      avgStackPerDay = Future.value(stats['avgStackPerDay']);
      timePerCardAnschauen = Future.value(stats['timePerCardAnschauen']);
      timePerCardDurcharbeiten = Future.value(stats['timePerCardDurcharbeiten']);
      maxStackPerDay = Future.value(stats['maxStackPerDay']);
    });
  }

  Widget buildStatRow(String title, Future<String> future) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title:",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
        ),
        FutureBuilder<String>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text(
                snapshot.data as String,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
              );
            }
          },
        ),
        buildLine(getColorByRechtsgebiet("", context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statisik'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildStatRow("Gesamtanzahl der Karteikarten", totalAnzahl),
            buildStatRow("Gesamtzeit", totalZeit),
            buildStatRow("Gesamtzeit heute", totalZeitToday),
            buildStatRow("Zeit beim Anschauen", timePerCardAnschauen),
            buildStatRow("Zeit beim Durcharbeiten", timePerCardDurcharbeiten),
            buildStatRow("Höchstdauer pro Tag", maxTimePerDay),
            buildStatRow("Durchschnitt pro Tag", avgTimePerDay),
            buildStatRow("Höchste Anzahl an Stapel pro Tag", maxStackPerDay),
            buildStatRow("Durchschnittliche Anzahl an Stapel pro Tag", avgStackPerDay),
          ],
        ),
      ),
    );
  }
}
