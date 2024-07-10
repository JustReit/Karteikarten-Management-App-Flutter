import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karteikarten_manager/database/databaseHelper.dart';

import 'package:karteikarten_manager/service/constants.dart';

String getControllTitle(int i) {
  // every time this gets called the counter should increment by one

  var title = "2. Kontrolle";
  if (i == 1){
    titlecounter++;
    title = "$titlecounter. Durchgang";
  }
  return title;
}
Color getColorByRechtsgebiet(String? selectedOption, BuildContext context) {
  // Define a map to map each option to its respective color
  Map<String, Color> optionColors = {
    'Zivilrecht 1': const Color(0xFF1976D2),
    'Zivilrecht 2': const Color(0xFF0D47A1), // Darker blue
    'Öffentliches Recht': const Color(0xFFD7A323),
    'Strafrecht': const Color(0xFFE64A19),
  };

  // Get the primary color of the current theme
  Color primaryColor = Theme
      .of(context)
      .colorScheme
      .inversePrimary;

  // Determine the color based on the selected option
  return selectedOption != null
      ? optionColors[selectedOption] ?? primaryColor // Use option color if available, otherwise fallback to brown
      : primaryColor; // Use the primary color of the theme if no option is selected
}


void showErrorMessage(BuildContext context, String s) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title:  Text("Eingabe fehlt bei $s"),
        content: const Text("Bitte Eingabe hinzufügen."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


String getWeekdayName(int index) {
  List<String> weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
  return weekdays[index];
}
bool isRestday(DateTime nextDate, String selectedRestDay) {
  // Check if the next date is a rest day
  return  DateFormat.EEEE('de_DE').format(nextDate).toString() == selectedRestDay;

}
String getWiederholungsDate(List<String> dates, List<String> times) {
  // Iterate through the date data from back to front
  for (int i = dates.length - 1; i >= 0; i--) {
    // Check if the current date and its previous time are not empty
    if (dates[i].isNotEmpty && i > 0 && times[i - 1].isNotEmpty) {
      // Return the text of the current date
      return dates[i];
    }
  }
  // If the conditions are not met for any date, return the first date
  return dates.isNotEmpty ? dates[0] : '';
}


DateTime? parseDate(String date) {
  try {
    // Trim whitespace and commas from the date string
    date = date.trim().replaceAll(',', '');

    // Split the date string by '.' and reverse it to match the format 'yy.mm.dd'
    List<String> parts = date.split('.').reversed.toList();

    // Parse the date string into a DateTime object
    return DateTime(
      int.parse(parts[0]) + 2000,
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (e) {
    return null;
  }
}


bool isTimeFormat(String? text) {
  // Regular expression to match the time format of "hh:mm"
  RegExp timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
  return timeRegex.hasMatch(text ?? "");
}

bool isDateFormat(String? text) {
  // Regular expression to match the date format of "dd.MM.yy"
  RegExp dateRegex = RegExp(r'^\d{2}.\d{2}.\d{2}$');
  return dateRegex.hasMatch(text ?? "");
}


Future<void> createStudyPlan(DateTime timeFrame, int amountPerDay, List<String> restDays,  List<String> zrDays,  List<String> oerDays , List<String> srDays) async {
  List<Map<String, dynamic>> data = await DatabaseHelper().getAllData();
  DateTime initialDate = DateTime.now();
  DateTime endDate = timeFrame;
  // Initialize counters and last initial dates for rechtsgebiete
  Map<String, int> rechtsgebietCounters = {
    'Zivilrecht': 0,
    'Öffentliches': 0,
    'Strafrecht': 0
  };
  Map<String, DateTime> lastInitialDates = {
    'Zivilrecht': DateTime.now(),
    'Öffentliches': DateTime.now(),
    'Strafrecht': DateTime.now()
  };
  Map<String, List<String>> daysStingMap = {
    'Zivilrecht': zrDays,
    'Öffentliches': oerDays,
    'Strafrecht': srDays
  };
    // Iterate over each data point
    for (var entry in data) {
      // Get the date from getWiederholungsDate
      DateTime? wiederholungsDate = parseDate(getWiederholungsDate(entry['dates'], entry['times']));
      String selectedOption = entry['selectedOption'];

      // Get the corresponding rechtsgebiet
      String rechtsgebiet = selectedOption.split(' ')[0];
      // Check if the current date is past the returned date or returned Date is past endDate
      if (DateTime.now().isAfter(wiederholungsDate!) || wiederholungsDate.isAfter(endDate)) {
        // Check if the current date is a rest day or not a day for the Rechtsgebiet
        initialDate = lastInitialDates[rechtsgebiet]!;
        while (restDays.contains(DateFormat.EEEE('de_DE').format(initialDate).toString()) || !daysStingMap[rechtsgebiet]!.contains(DateFormat.EEEE('de_DE').format(initialDate).toString())) {
          initialDate = initialDate.add(const Duration(days: 1));
        }
        while (restDays.contains(DateFormat.EEEE('de_DE').format(initialDate).toString()) || !daysStingMap[rechtsgebiet]!.contains(DateFormat.EEEE('de_DE').format(initialDate).toString())) {
          initialDate = initialDate.add(const Duration(days: 1));
        }
        // Update the entry with the new date
        List<String> updatedDates = List.from(entry['dates']);
        int index = updatedDates.indexOf(getWiederholungsDate(entry['dates'], entry['times']));
        updatedDates[index] = dateFormat.format(initialDate);
        await DatabaseHelper().updateDates(entry['id'], updatedDates);

        // Reset the counter if it exceeds amountPerDay
        if (rechtsgebietCounters[rechtsgebiet]! >= amountPerDay) {
          rechtsgebietCounters[rechtsgebiet] = 0;
          initialDate = initialDate.add(const Duration(days: 1));
          // Get the next fitting weekday based on the selected option
        }
        // Increment the counter and mark changes
        rechtsgebietCounters[rechtsgebiet] =  rechtsgebietCounters[rechtsgebiet]! + 1;
        lastInitialDates[rechtsgebiet] = initialDate;

      }
    }

  }

Future<List<Map<String, dynamic>>> sortData(
    String sortingType, bool displayAllCards) async {
  List<Map<String, dynamic>> data;
  if (displayAllCards) {
    data = await DatabaseHelper().getAllData();
  } else {
    data = await DatabaseHelper().getDataForToday();
  }
  data.sort((a, b) {
    if (sortingType == 'dates') {
      // Sorting by dates in ascending order
      String dateA = getWiederholungsDate(a['dates'], a['times']);
      String dateB = getWiederholungsDate(b['dates'], b['times']);

      DateTime? dateTimeA = parseDate(dateA);
      DateTime? dateTimeB = parseDate(dateB);

      return dateTimeA!.compareTo(dateTimeB!);
    } else if (sortingType == 'anzahl' || sortingType == 'id') {
      // Sorting by anzahl in descending order
      int valueA = a[sortingType];
      int valueB = b[sortingType];
      return valueB.compareTo(valueA); // Compare in descending order
    } else {
      // Sorting by thema or selectedOption
      String valueA = a[sortingType];
      String valueB = b[sortingType];
      return valueA.compareTo(valueB);
    }
  });

  return data;
}

Future<void> changeWiederholungsDate(int id, dates, times , String newWiederholungsDate) async {
  // Update the entry with the new date
  int index = dates.indexOf(getWiederholungsDate(dates, times));
  dates[index] = newWiederholungsDate;
  await DatabaseHelper().updateDates(id, dates);

}
