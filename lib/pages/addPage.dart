import 'package:flutter/material.dart';
import 'package:karteikarten_manager/database/databaseHelper.dart';
import 'package:karteikarten_manager/service/constants.dart';

import 'package:karteikarten_manager/service/functions.dart';
import 'package:karteikarten_manager/service/uiElements.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPage extends StatefulWidget {
  final int counter;

  // Constructor to receive the counter value
  const AddPage(this.counter, {Key? key}) : super(key: key);

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  late DatabaseHelper databaseHelper;
  late int _count; // Declare _count variable
  String? rechtsGebiet;
  bool fillDatesAutomatically = true;
  String selectedRestDay = 'Sonntag';
  List<TextEditingController> _dateControllers = [];
  List<TextEditingController> _timeControllers = [];
  List<TextEditingController> _rechtsControllers = [];
  final TextEditingController _themaController = TextEditingController();
  final TextEditingController _anzahlController = TextEditingController();
  late SharedPreferences _prefs;

  // Load theme preference from SharedPreferences


  @override
  void initState() {
    super.initState();
    _count = widget.counter;
    _updateControllers(); // Initialize controllers
    _loadPrefs();
    databaseHelper = DatabaseHelper();

  }



  _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    fillDatesAutomatically = _prefs.getBool('fillDatesAutomatically') ?? true;
    selectedRestDay = _prefs.getString('selectedRestDay') ?? 'Sonntag';
    if(fillDatesAutomatically){
      _fillDates();
    }
  }
  void _fillDates() {
    // Assuming _dateControllers is already initialized
    DateTime today = DateTime.now();
    _dateControllers[0].text = dateFormat.format(today).toString();
    _dateControllers[1].text = dateFormat.format(today).toString();

    DateTime nextDate = today.add(const Duration(days: 1));
    if(isRestday(nextDate, selectedRestDay)){
       nextDate = nextDate.add(const Duration(days: 1));
    }
    for (int i = 2; i < 6; i++) {
      _dateControllers[i].text = dateFormat.format(nextDate).toString();
      nextDate = nextDate.add(const Duration(days: 1));
      if(isRestday(nextDate, selectedRestDay)){
        nextDate = nextDate.add(const Duration(days: 1));
      }
    }
    nextDate = today.add(const Duration(days: 6));
    if(isRestday(nextDate, selectedRestDay)){
      nextDate = nextDate.subtract(const Duration(days: 1));
    }
    _dateControllers[5].text = dateFormat.format(nextDate).toString();
    nextDate = nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
    if(isRestday(nextDate, selectedRestDay)){
      nextDate = nextDate.add(const Duration(days: 1));
    }
    for (int i = 6; i < 10; i++) {
      _dateControllers[i].text = dateFormat.format(nextDate).toString();
      nextDate = nextDate.add(const Duration(days: 1));
      if(isRestday(nextDate, selectedRestDay)){
        nextDate = nextDate.add(const Duration(days: 1));
      }
    }
    nextDate = nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
    for (int i = 10; i <13; i++) {
      _dateControllers[i].text = dateFormat.format(nextDate).toString();
      nextDate = nextDate.add(const Duration(days: 1));
      if(isRestday(nextDate, selectedRestDay)){
        nextDate = nextDate.add(const Duration(days: 1));
      };
    }
  }

  void _updateControllers() {
    titlecounter = 1;
    _dateControllers = List.generate(
      _count + 7,
          (index) => TextEditingController(),
    );
    _timeControllers = List.generate(
      _count + 7,
          (index) => TextEditingController(),
    );
    _rechtsControllers = List.generate(
      _count + 7,
          (index) => TextEditingController(),
    );
    for (int i = 0; i < _dateControllers.length; i++) {
      _dateControllers[i].addListener(expandCount);
      _timeControllers[i].addListener(expandCount);
      _rechtsControllers[i].addListener(expandCount);
    }
  }


  @override
  void dispose() {
    for (var controller in _dateControllers) {
      controller.dispose();
    }
    for (var controller in _timeControllers) {
      controller.dispose();
    }
    for (var controller in _rechtsControllers) {
      controller.dispose();
    }
    _themaController.dispose();
    _anzahlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    titlecounter = 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stapel hinzufügen'),
        backgroundColor: getColorByRechtsgebiet(rechtsGebiet,context),
      ),
      body: ListView(
        children: [
          Container(
            color: getColorByRechtsgebiet(rechtsGebiet,context),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Rechtsgebiet',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Wähle Rechtsgebiet aus"),
                      value: null, // Use null check for selectedOption
                      onChanged: (String? newValue) {
                        setState(() {
                          rechtsGebiet = newValue!;
                          expandCount();
                        });
                      },
                      items: rechtsgebietOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Input for Thema
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _themaController,
                    decoration: const InputDecoration(
                        labelText: 'Thema', border: OutlineInputBorder()),
                  ),
                ),
              ),

              // Input for Anzahl
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _anzahlController,
                    decoration: const InputDecoration(
                        labelText: 'Anzahl', border: OutlineInputBorder()),
                    keyboardType:
                        TextInputType.number, // Allowing only numeric input
                  ),
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16.0)),
          //Anschauen
          buildTitle("Anschauen"),
          buildRow(context, _dateControllers[0], _timeControllers[0],
              _rechtsControllers[0], 'Datum ', 'Zeit', false, selectedRestDay),
          //Durcharbeiten
          buildTitle("Durcharbeiten"),
          buildRow(context, _dateControllers[1], _timeControllers[1],
              _rechtsControllers[1], 'Datum ', 'Zeit', false, selectedRestDay),
          buildLine(getColorByRechtsgebiet(rechtsGebiet, context)),
          //Erster Durchgang
          for (int i = 0; i < 4; i++)
            Column(
              children: [
                if (i == 3) ...[
                  buildTitle("G Kontrolle"),
                  buildRow(
                      context,
                      _dateControllers[i + 2],
                      _timeControllers[i + 2],
                      _rechtsControllers[i + 2],
                      'Datum ',
                      'Zeit',
                      true,
                      selectedRestDay),
                  buildLine(getColorByRechtsgebiet(rechtsGebiet, context)),
                ] else ...[
                  buildTitle("${i + 1}. Kontrolle"),
                  buildRow(
                      context,
                      _dateControllers[i + 2],
                      _timeControllers[i + 2],
                      _rechtsControllers[i + 2],
                      'Datum ',
                      'Zeit',
                      true,
                      selectedRestDay),
                ],
              ],
            ),
          // ListView.builder to display additional rows based on _count
          //Weitere Durchgänge
          ListView.builder(
            shrinkWrap:
            true, // Add shrinkWrap to enable scrolling inside ListView.builder
            physics:
            const NeverScrollableScrollPhysics(), // Disable scrolling for the inner ListView.builder
            itemCount: _count,
            itemBuilder: (BuildContext context, int rowIndex) {
              // Add a _buildTitle before each row
              return Column(
                children: [
                  if ((rowIndex + 4) % 3 == 0) ...[
                    buildTitle("3. Kontrolle"),
                    buildRow(
                        context,
                        _dateControllers[rowIndex + 7],
                        _timeControllers[rowIndex + 7],
                        _rechtsControllers[rowIndex + 7],
                        'Datum ',
                        'Zeit',
                        true,
                        selectedRestDay),
                    buildLine(getColorByRechtsgebiet(rechtsGebiet, context)),
                  ] else ...[
                    buildTitle(getControllTitle(((rowIndex + 4) % 3))),
                    buildRow(
                        context,
                        _dateControllers[rowIndex + 7],
                        _timeControllers[rowIndex + 7],
                        _rechtsControllers[rowIndex + 7],
                        'Datum ',
                        'Zeit',
                        true,
                        selectedRestDay),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          if (rechtsGebiet != null) {
            _checkForEmptyInputs( _themaController.text,
              int.tryParse(_anzahlController.text) ?? 0,
            );
          } else {
            // Show a popup message informing the user to select an option
            showErrorMessage(context, "Rechtsgebiet");
          }

        },
        child: const Icon(Icons.save_outlined),
      ),
    );
  }


  Future<void> _saveData() async {
    // Initialize lists to store parsed data
    List<String> dates = [];
    List<String> times = [];
    List<int> rechtsValues = [];
    int anzahl = int.tryParse(_anzahlController.text) ?? 0;
    // Iterate through date and time controllers to extract data
    for (int i = 0; i < _dateControllers.length; i++) {
      // Validate date format
      String dateText = _dateControllers[i].text.trim();
      if (dateText.isEmpty || isDateFormat(dateText)) {
        dates.add(dateText);
      } else {
        dates.add("");
      }

      // Validate time format
      String timeText = _timeControllers[i].text.trim();
      if (timeText.isEmpty || isTimeFormat(timeText)) {
        times.add(timeText);
      } else {
        times.add("");
      }
    }
    for (int i = 0; i < _rechtsControllers.length; i++) {
      int rechts = int.tryParse(_rechtsControllers[i].text) ?? 0;
      if(rechts > anzahl){
        var snackBar = SnackBar(
          content: Text(' Wert von Rechts ($rechts) größer als die Anzahl ($anzahl)'),
          duration: const Duration(seconds:5),
        );
        // Get the context of the nearest Scaffold and show the SnackBar
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }else{
        rechtsValues.add(rechts);
      }
    }

    await databaseHelper.insertData(
      rechtsGebiet!,
      _themaController.text,
      anzahl,
      dates,
      times,
      rechtsValues,
    );
    Navigator.of(context).pop();
  }
  void  _checkForEmptyInputs(
      String thema,
      int anzahl,
      ) {

    if (thema.isEmpty) {
      showErrorMessage(context, "Thema");
    }
    else if (anzahl == 0) {
      showErrorMessage(context, "Anzahl");
    } else {
      _saveData();

    }
  }
  void expandCount() {
    // Initialize lists to store existing values
    List<String> existingDates = [];
    List<String> existingTimes = [];
    List<String> existingRechts = [];

    // Store existing values from the current controllers
    for (int i = 0; i < _dateControllers.length; i++) {
      existingDates.add(_dateControllers[i].text);
      existingTimes.add(_timeControllers[i].text);
      existingRechts.add(_rechtsControllers[i].text);
    }

    // Iterate through all _dateControllers.text from back to front
    for (int i = _dateControllers.length - 1; i >= 0; i--) {
      // Check if the text of the current date controller is empty
      if (_dateControllers[i].text.isNotEmpty && i > _dateControllers.length - 4) {
        setState(() {
          _count += 3; // Increment _count by 3
          _updateControllers();
          // Restore existing values to the newly created controllers
          for (int j = 0; j < _dateControllers.length - 3; j++) {
            _dateControllers[j].text = existingDates[j];
            _timeControllers[j].text = existingTimes[j];
            _rechtsControllers[j].text = existingRechts[j];
          }
        });
        break; // Break the loop after incrementing _count
      }
    }
  }


}







