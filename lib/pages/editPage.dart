import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karteikarten_manager/database/databaseHelper.dart';
import 'package:karteikarten_manager/service/constants.dart';
import 'package:karteikarten_manager/service/functions.dart';
import 'package:karteikarten_manager/service/uiElements.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPage extends StatefulWidget {
  final int id;
  // Constructor to receive the counter value
  const EditPage(this.id, {Key? key}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late DatabaseHelper databaseHelper;
  late int _count = 9; // Declare _count variable
  late int _id; // Declare _count variable
  late final List<List<Map<String, dynamic>>> data;

  String? rechtsGebiet;
  String selectedRestDay = 'Sonntag';
  List<TextEditingController> _dateControllers = [];
  List<TextEditingController> _timeControllers = [];
  List<TextEditingController> _rechtsControllers = [];
  final TextEditingController _themaController = TextEditingController();
  final TextEditingController _anzahlController = TextEditingController();
  late SharedPreferences _prefs;
  @override
  void initState() {
    super.initState();
    _loadTheme();
    _updateControllers();
    _id = widget.id;
    databaseHelper = DatabaseHelper();
    _getDataAndUpdateState();


  }

  _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();

    selectedRestDay = _prefs.getString('selectedRestDay') ?? 'Sonntag';
  }

  Future<void> _getDataAndUpdateState() async {
    final data = await databaseHelper.getDataById(_id);
    if (data != null && data.isNotEmpty) {
      setState(() {
        // Assuming there's only one item in the list
        Map<String, dynamic> rowData = data;
        var count = rowData["dates"].length - 7;
        if (count != _count && (count) > 9) {
          _count = count;
          _updateControllers();
        }
        _updateControllers(); // Initialize controllers
        rechtsGebiet = rowData['selectedOption'];
        _themaController.text = rowData['thema'];
        _anzahlController.text = rowData['anzahl'].toString();
        // Initialize date and time controllers with data
        for (int i = 0; i < rowData['dates'].length; i++) {
          _dateControllers[i].text = rowData['dates'][i];
          _timeControllers[i].text = rowData['times'][i];
        }
        for (int i = 0; i < rowData['rechtsValues'].length; i++) {
          var rechtsValue = rowData['rechtsValues'][i].toString();
          if (rechtsValue != "0") {
            _rechtsControllers[i].text = rechtsValue;
          } else if (rechtsValue == "0" &&
              _timeControllers[i].text.isNotEmpty) {
            _rechtsControllers[i].text = rechtsValue;
          }
        }
      });
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

  //fill out inputs based on the dat  provided by the _data
  @override
  Widget build(BuildContext context) {



    // List of options for the dropdown menu

    titlecounter = 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bearbeiten'),
        backgroundColor: getColorByRechtsgebiet(rechtsGebiet, context),
      ),
      body: ListView(
        children: [
          Container(
            color: getColorByRechtsgebiet(rechtsGebiet, context),
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
                      value: rechtsGebiet, // Use null check for selectedOption
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
        onPressed: () {
          if (rechtsGebiet != null) {
            _checkForEmptyInputs(
              _themaController.text,
              int.tryParse(_anzahlController.text) ?? 0,
            );
          } else {
            // Show a popup message informing the user to select an option
            showErrorMessage(context, "Rechtsgebiet");
          }
        },
        child: const Icon(Icons.save_as_outlined),
      ),
    );
  }

  Future<void> _editData() async {
    // Initialize lists to store parsed data
    List<String> dates = [];
    List<String> times = [];
    List<int> rechtsValues = [];

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
      rechtsValues.add(rechts);
    }

    await databaseHelper.updateData(
      _id,
      rechtsGebiet!,
      _themaController.text,
      int.tryParse(_anzahlController.text) ?? 0,
      dates,
      times,
      rechtsValues,
    );
  }

  void _checkForEmptyInputs(
    String thema,
    int anzahl,
  ) {
    if (thema.isEmpty) {
      showErrorMessage(context, "Thema");
    } else if (anzahl == 0) {
      showErrorMessage(context, "Anzahl");
    } else {
      _editData();
      Navigator.of(context).pop();
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
      if (_dateControllers[i].text.isNotEmpty &&
          i > _dateControllers.length - 4) {
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
