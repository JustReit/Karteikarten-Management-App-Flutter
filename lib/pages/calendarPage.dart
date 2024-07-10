import 'package:flutter/material.dart';
import 'package:flutter_neat_and_clean_calendar/flutter_neat_and_clean_calendar.dart';
import 'package:karteikarten_manager/database/databaseHelper.dart';
import 'package:karteikarten_manager/pages/editPage.dart';
import 'package:karteikarten_manager/service/functions.dart';


class CalendarPage extends StatefulWidget {


  // Constructor to receive the counter value
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DatabaseHelper databaseHelper;
  late String wiederholungsDate;
  late final List<NeatCleanCalendarEvent> _eventList = [];



  void _loadCalendarData() async {
    // Fetch data from the database
    List<Map<String, dynamic>> data = await databaseHelper.getAllData();

    // Create a list to store the events
    List<NeatCleanCalendarEvent> events = [];

    // Iterate over the fetched data and convert it to NeatCleanCalendarEvent objects
    for (Map<String, dynamic> entry in data) {
      // Assuming 'dates' and 'times' are List<String> in the database
      List<String> dates = entry['dates'] ?? [];
      wiederholungsDate = getWiederholungsDate(entry['dates'], entry['times']);
      // Combine dates and times to create DateTime objects for start and end time
      for (int i = 0; i < dates.length; i++) {
        bool done = false;
        DateTime? date = parseDate(dates[i]);
        if(date != null) {
          if(entry['times'][i] != "" && DateTime.now().isAfter(date)) {
            done = true;
          }
          String title = entry['thema'];
          if(title.length >= 24) {
            title = "${title.substring(0, 24)}...";
          }
          DateTime? startTime = date;
          DateTime endTime = startTime.add(
              const Duration(hours: 0)); // Assuming event duration is 1 hour
          events.add(
            NeatCleanCalendarEvent(
              title, // Assuming 'thema' is the event title
              description: "${entry['anzahl']} Karteikarten",
              metadata: entry,
              startTime: startTime,
              endTime: endTime,
              color: getColorByRechtsgebiet(entry['selectedOption'], context),
              // Set your desired color here
              isAllDay: true,
              // Assuming it's not an all-day event
              isDone: done,
            ),
          );
        }
      }
    }

    // Update _eventList with the fetched events
    setState(() {
      _eventList.clear();
      _eventList.addAll(events);
    });
  }



  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadCalendarData();

  }


  @override
  Widget build(BuildContext context) {
    Color textColor = Theme
        .of(context)
        .colorScheme
        .inverseSurface;
    return Scaffold(
      body: Calendar(
        startOnMonday: true,
        weekDays: const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
        eventsList: _eventList,
        eventTileHeight: MediaQuery.of(context).size.height * 0.09,
        isExpandable: false,
        defaultDayColor: textColor,
        eventDoneColor: Colors.green,
        selectedColor:Colors.blue,
        selectedTodayColor: Colors.indigo[900]!,
        todayColor: Colors.deepOrange,
        locale: 'de_DE',
        todayButtonText: '',
        allDayEventText: '',
        isExpanded: true,
        expandableDateFormat: 'EEEE, dd. MMMM yyyy',
          onEventSelected: (value) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditPage(value.metadata?['id'])),
            );
          },

        datePickerType: DatePickerType.date,
        dayOfWeekStyle: TextStyle(
            color: textColor, fontWeight: FontWeight.w800, fontSize: 11),

        showEvents: true,
      ),

    );
  }

}


