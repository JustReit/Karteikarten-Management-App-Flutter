import 'package:karteikarten_manager/service/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import "package:path/path.dart" as pth;

import 'dart:async';


import '../service/functions.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  DatabaseHelper.internal();

  Future<Database> _initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = pth.join(documentsDirectory.path, 'Karteikarten_Stapel.db');
    var ourDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return ourDb;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE KarteikartenStapel (
      id INTEGER PRIMARY KEY,
      selectedOption TEXT,
      thema TEXT,
      anzahl INTEGER,
      dates TEXT,
      times TEXT,
      rechtsValues TEXT
    )

    ''');
  }

  Future<int> insertData(String selectedOption, String thema, int anzahl,
      List<String> dates, List<String> times, List<int> rechtsValues) async {
    Database dbClient = await db;
    String datesString =
        dates.join(','); // Convert lists to comma-separated strings
    String timesString = times.join(',');
    String rechtsValuesString = rechtsValues.join(',');
    return await dbClient.insert('KarteikartenStapel', {
      'selectedOption': selectedOption,
      'thema': thema,
      'anzahl': anzahl,
      'dates': datesString,
      'times': timesString,
      'rechtsValues': rechtsValuesString,
    });
  }

  Future<int> deleteData(int id) async {
    Database dbClient = await db;
    return await dbClient
        .delete('KarteikartenStapel', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateData(
      int id,
      String selectedOption,
      String thema,
      int anzahl,
      List<String> dates,
      List<String> times,
      List<int> rechtsValues) async {
    Database dbClient = await db;
    String datesString = dates.join(',');
    String timesString = times.join(',');
    String rechtsValuesString = rechtsValues.join(',');

    return await dbClient.update(
        'KarteikartenStapel',
        {
          'selectedOption': selectedOption,
          'thema': thema,
          'anzahl': anzahl,
          'dates': datesString,
          'times': timesString,
          'rechtsValues': rechtsValuesString,
        },
        where: 'id = ?',
        whereArgs: [id]);
  }
  Future<int> updateDates(int id, List<String> dates) async {
    try {
      Database dbClient = await db;
      String datesString = dates.join(',');
      return await dbClient.update(
        'KarteikartenStapel',
        {'dates': datesString},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating dates: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllData() async {
    try {
      Database dbClient = await db;
      List<Map<String, dynamic>> result =
      await dbClient.query('KarteikartenStapel');
      List<Map<String, dynamic>> parsedResult = result.map((map) {
        List<String> dates = (map['dates'] as String).split(',');
        List<String> times = (map['times'] as String).split(',');
        List<int> rechtsValues = (map['rechtsValues'] as String)
            .split(',')
            .map((s) => int.tryParse(s) ?? 0) // Handle parsing errors
            .toList();
        return {
          ...map,
          'dates': dates,
          'times': times,
          'rechtsValues': rechtsValues,
          'anzahl': map['anzahl'] as int, // Parse 'anzahl' to integer
        };
      }).toList();
      return parsedResult;
    } catch (e, stackTrace) {
      // Print the error and stack trace
      print('Error occurred in getAllData(): $e');
      print('Stack trace: $stackTrace');
      // You can also log the error to a file or analytics service if needed
      // Return an empty list or handle the error in an appropriate way
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getDataForToday() async {
    try {
      Database dbClient = await db;
      List<Map<String, dynamic>> result =
      await dbClient.query('KarteikartenStapel');
      List<Map<String, dynamic>> filteredData = [];

      DateTime today = DateTime.now();
      String todayFormatted = dateFormat.format(today);

      for (Map<String, dynamic> map in result) {
        List<String> dates = (map['dates'] as String).split(',');
        List<String> times = (map['times'] as String).split(',');

        String widerholungsDate = getWiederholungsDate(dates, times);
        if (widerholungsDate == todayFormatted) {
          filteredData.add({
            ...map,
            'dates': dates,
            'times': times,
            'rechtsValues': (map['rechtsValues'] as String)
                .split(',')
                .map((s) => int.tryParse(s) ?? 0)
                .toList(),
            'anzahl': map['anzahl'] as int,
          });
        }
      }
      return filteredData;
    } catch (e, stackTrace) {
      // Print the error and stack trace
      print('Error occurred in getDataForToday(): $e');
      print('Stack trace: $stackTrace');
      // You can also log the error to a file or analytics service if needed
      // Return an empty list or handle the error in an appropriate way
      return [];
    }
  }



  Future<Map<String, dynamic>?> getDataById(int id) async {
    Database dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient
        .query('KarteikartenStapel', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    Map<String, dynamic> map = result.first;
    List<String> dates = (map['dates'] as String).split(',');
    List<String> times = (map['times'] as String).split(',');
    List<int> rechtsValues = (map['rechtsValues'] as String)
        .split(',')
        .map((s) => int.parse(s))
        .toList();
    return {
      ...map,
      'dates': dates,
      'times': times,
      'rechtsValues': rechtsValues,
      'anzahl': map['anzahl'] as int, // Parse 'anzahl' to integer
    };
  }

  Future<String> getTotalAnzahl(List<Map<String, dynamic>> result) async {
    int sum = 0;
    for (Map<String, dynamic> map in result) {
      sum += map['anzahl'] as int;
    }
    return sum.toString();
  }

  Future<String> getTotalTime(List<Map<String, dynamic>> result) async {

    int totalMinutes = 0;

    for (Map<String, dynamic> map in result) {
      List<String> times = (map['times'] as String).split(',');
      for (String time in times) {
        if (time.isNotEmpty) {
          List<String> parts = time.split(':');
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          totalMinutes += hours * 60 + minutes;
        }
      }
    }

    int totalHours = totalMinutes ~/ 60;
    int remainingMinutes = totalMinutes % 60;

    return '$totalHours Stunden und ${remainingMinutes.toString().padLeft(2, '0')} Minuten';
  }

  Future<String> getTotalTimeSpentToday(List<Map<String, dynamic>> result) async {

    int totalMinutes = 0;

    DateTime today = DateTime.now();
    String todayFormatted = dateFormat.format(today);

    for (Map<String, dynamic> map in result) {
      List<String> dates = (map['dates'] as String).split(',');
      List<String> times = (map['times'] as String).split(',');

      for (int i = 0; i < dates.length; i++) {
        if (dates[i] == todayFormatted && times[i].isNotEmpty) {
          List<String> parts = times[i].split(':');
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          totalMinutes += hours * 60 + minutes;
        }
      }
    }

    int totalHours = totalMinutes ~/ 60;
    int remainingMinutes = totalMinutes % 60;

    return '$totalHours Stunden und ${remainingMinutes.toString().padLeft(2, '0')} Minuten';
  }
  Future<String> getMaxTimeSpentPerDay(List<Map<String, dynamic>> result) async {

    Map<String, int> totalMinutesPerDay = {};

    // Calculate total minutes spent per day
    for (Map<String, dynamic> map in result) {
      List<String> dates = (map['dates'] as String).split(',');
      List<String> times = (map['times'] as String).split(',');

      for (int i = 0; i < dates.length; i++) {
        if (times[i].isNotEmpty) {
          List<String> parts = times[i].split(':');
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          int totalMinutes = hours * 60 + minutes;

          totalMinutesPerDay[dates[i]] = (totalMinutesPerDay[dates[i]] ?? 0) + totalMinutes;
        }
      }
    }

    // Find the day with the maximum total minutes spent
    String dayWithMaxTimeSpent = '';
    int maxTimeSpent = 0;

    totalMinutesPerDay.forEach((day, totalMinutes) {
      if (totalMinutes > maxTimeSpent) {
        maxTimeSpent = totalMinutes;
        dayWithMaxTimeSpent = day;
      }
    });

    int totalHours = maxTimeSpent ~/ 60;
    int remainingMinutes = maxTimeSpent % 60;

    return '$totalHours Stunden und ${remainingMinutes.toString().padLeft(2, '0')} Minuten am $dayWithMaxTimeSpent';
  }
  Future<List<String>> getMaxCompletedStacksAndAvgPerDay(List<Map<String, dynamic>> result) async {
    Map<String, int> completedStacksPerDay = {}; // To store the completed stacks count for each day
    Set<String> uniqueDates = {}; // To store unique dates

    for (Map<String, dynamic> map in result) {
      List<String> dates = (map['dates'] as String).split(',');
      List<String> times = (map['times'] as String).split(',');

      Set<String> uniqueDatesInRow = {}; // To keep track of unique dates in each row

      for (int i = 0; i < dates.length; i++) {
        if (dates[i].isNotEmpty && times[i].isNotEmpty && times[i] != '00:00' && !uniqueDatesInRow.contains(dates[i])) {
          uniqueDatesInRow.add(dates[i]);
        }
      }

      // Increment completed stacks count for each date encountered in the row
      for (String date in uniqueDatesInRow) {
        completedStacksPerDay[date] = (completedStacksPerDay[date] ?? 0) + 1;
        uniqueDates.add(date); // Add the date to the set of unique dates
      }
    }

    // Calculate the total number of stacks and the total number of days
    int totalStacks = completedStacksPerDay.values.isNotEmpty
        ? completedStacksPerDay.values.reduce((value, element) => value + element)
        : 0;
    int totalDays = uniqueDates.length;

    // Calculate the average number of stacks per day
    double averageStacksPerDay = totalDays > 0 ? totalStacks / totalDays : 0;

    // Find the maximum completed stacks count among all dates
    int maxCompletedStacks = completedStacksPerDay.values.isNotEmpty
        ? completedStacksPerDay.values.reduce((value, element) => value > element ? value : element)
        : 0;

    // Find the date with the maximum completed stacks count
    String maxCompletedDate = '';
    completedStacksPerDay.forEach((date, count) {
      if (count == maxCompletedStacks) {
        maxCompletedDate = date;
      }
    });

    return ['$maxCompletedStacks Stapel pro Tag am $maxCompletedDate', 'Durchschnittlich ${averageStacksPerDay.toStringAsPrecision(2)} Stapel pro Tag'];
  }
  Future<String> getAverageTimeSpentPerDay(List<Map<String, dynamic>> result) async {

    Map<String, int> totalMinutesPerDay = {};
    Set<String> uniqueDays = {};

    // Calculate total minutes spent per day and count total unique days
    for (Map<String, dynamic> map in result) {
      List<String> dates = (map['dates'] as String).split(',');
      List<String> times = (map['times'] as String).split(',');

      for (int i = 0; i < dates.length; i++) {
        if (times[i].isNotEmpty &&  times[i] != "00:00") {
          List<String> parts = times[i].split(':');
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          int totalMinutes = hours * 60 + minutes;

          totalMinutesPerDay[dates[i]] = (totalMinutesPerDay[dates[i]] ?? 0) + totalMinutes;
          if(!uniqueDays.contains(dates[i])){
            uniqueDays.add(dates[i]);
          }
        }
      }
    }

    // Calculate total time spent
    int totalTimeSpent = totalMinutesPerDay.values.fold(0, (sum, minutes) => sum + minutes);

    // Calculate average time spent per day
    num averageTimeSpentPerDayInMinutes = uniqueDays.isNotEmpty ? totalTimeSpent / uniqueDays.length : 0;

    int averageHours = (averageTimeSpentPerDayInMinutes / 60).floor();
    int averageMinutes = (averageTimeSpentPerDayInMinutes % 60).round();

    return '$averageHours Stunden und $averageMinutes Minuten pro Tag.';
  }

  Future<String> calculateSecondsPerCard(int i, List<Map<String, dynamic>> result) async {

    int totalSeconds = 0;
    int totalAnzahl = 0;
    num secondsPerAnzahlUnit = 0.0;

    // Find the total seconds and total anzahl
    for (Map<String, dynamic> map in result) {
      List<String> times = (map['times'] as String).split(',');
      int anzahl = map['anzahl'] as int;

      if (times.length >= 2) {
        String secondTime = times[i]; // Accessing the second value
        if (secondTime.isNotEmpty) {
          List<String> parts = secondTime.split(':');
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          int seconds = hours * 3600 + minutes * 60;
          totalSeconds += seconds;
          totalAnzahl += anzahl;
        }
      }
    }
    if(totalAnzahl != 0){
      secondsPerAnzahlUnit = (totalSeconds ~/ totalAnzahl);
    }
    // Calculate seconds per anzahl unit

    return '$secondsPerAnzahlUnit Sekunden pro Karteikarte' ;
  }

  Future<Map<String, dynamic>> getStats() async {
    Database dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query('KarteikartenStapel');

    String totalAnzahlValue = await getTotalAnzahl(result);
    String totalZeitValue = await getTotalTime(result);
    String totalZeitTodayValue = await getTotalTimeSpentToday(result);
    String avgTimePerDayValue = await getAverageTimeSpentPerDay(result);
    String maxTimePerDayValue = await getMaxTimeSpentPerDay(result);
    List<String> maxStackAndAvgPerDayValues = await getMaxCompletedStacksAndAvgPerDay(result);
    String maxStackPerDayValue = maxStackAndAvgPerDayValues[0];
    String avgStackPerDayValue = maxStackAndAvgPerDayValues[1];
    String timePerCardAnschauenValue = await calculateSecondsPerCard(0, result);
    String timePerCardDurcharbeitenValue = await calculateSecondsPerCard(1, result);

    return {
      'totalAnzahl': totalAnzahlValue,
      'totalZeit': totalZeitValue,
      'totalZeitToday': totalZeitTodayValue,
      'avgTimePerDay': avgTimePerDayValue,
      'maxTimePerDay': maxTimePerDayValue,
      'avgStackPerDay': avgStackPerDayValue,
      'maxStackPerDay': maxStackPerDayValue,
      'timePerCardAnschauen': timePerCardAnschauenValue,
      'timePerCardDurcharbeiten': timePerCardDurcharbeitenValue,
    };
  }

}
