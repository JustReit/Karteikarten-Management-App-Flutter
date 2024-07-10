import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:karteikarten_manager/pages/calendarPage.dart';
import 'package:karteikarten_manager/pages/editPage.dart';
import 'package:karteikarten_manager/pages/settingsPage.dart';
import 'package:karteikarten_manager/pages/statsPage.dart';
import 'package:karteikarten_manager/service/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/databaseHelper.dart';
import '../service/functions.dart';
import '../service/sortingRadio.dart';
import 'addPage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  Future<List<Map<String, dynamic>>>? _dataFuture;
  DatabaseHelper databaseHelper = DatabaseHelper();
  late TextEditingController _searchController;
  late TextEditingController _dateController;

  //Settings
  late String _searchQuery = '';
  String sortingMethod = 'dates';
  bool displayAllCards = true;
  String selectedRestDay = 'Sonntag';

  //Set up Lernplan
  late SharedPreferences _prefs;
  late int amountPerDay = 0;
  int stapelPerDay = 0;
  late DateTime timeFrame;
  late int dataLength;
  late int selectedIndex = 0;
  List<bool> selectedRestdays = List<bool>.filled(7, false);
  List<bool> selectedZRdays = List<bool>.filled(7, false);
  List<bool> selectedSRdays = List<bool>.filled(7, false);
  List<bool> selectedOERdays = List<bool>.filled(7, false);
  List<List<bool>> disabledDays = List.generate(
      4,
          (_) => List.generate(
          7,
              (_) =>
          false)); // Initialize a 2D list to track disabled days for each category
  Set<int> selectedItems = {}; // To track selected items

  @override
  void initState() {
    super.initState();
    _loadPrefs(); // Wait until preferences are loaded
    _searchController = TextEditingController();
    _dateController = TextEditingController();
  }

  _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    displayAllCards = _prefs.getBool('displayAllCards') ?? true;
    sortingMethod = _prefs.getString('sortingMethod') ?? 'dates';
    selectedRestDay = _prefs.getString('selectedRestDay') ?? 'Sonntag';
    _dataFuture = sortData(sortingMethod, displayAllCards);
    _dataFuture?.then((data) {
      setState(() {
        dataLength = data.length;
      });
    });
  }

  _saveSortingMethod(String s) async {
    await _prefs.setString('sortingMethod', s);
    sortingMethod = s;
  }

  void updateDisabledDays() {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 7; j++) {
        disabledDays[i][j] = selectedRestdays[j];
      }
    }
  }

  void deleteItems(Set<int> ids) async {
    for (int id in ids) {
      await DatabaseHelper().deleteData(id);
    }
    setState(() {
      _dataFuture = sortData(sortingMethod, displayAllCards);
      selectedItems.clear(); // Clear selection after deletion
    });
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (MediaQuery.of(context).size.width / 150).floor();
    final screenHeight = (MediaQuery.of(context).size.height * 0.4);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Suche nach Karteikarten...',
            suffixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
        actions: selectedItems.isNotEmpty
            ? [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (pickedDate != null) {
                final formattedDate =
                dateFormat.format(pickedDate).toString();
                int id;
                for (id in selectedItems) {
                  final data = await databaseHelper.getDataById(id);
                  Map<String, dynamic>? item = data;
                  changeWiederholungsDate(
                      id, item?['dates'], item?['times'], formattedDate);
                }
                selectedItems.clear();
                setState(() {
                  _dataFuture = sortData(sortingMethod, displayAllCards);
                });
              }

            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Löschung bestätigen"),
                    content: const Text(
                        "Möchten Sie diese Einträge wirklich löschen?"),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Abbrechen"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text("Löschen"),
                        onPressed: () {
                          deleteItems(selectedItems);
                          setState(() {
                            _dataFuture =
                                sortData(sortingMethod, displayAllCards);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                selectedItems.clear();
              });
            },
          ),
        ]
            : [],
      ),
      body: selectedIndex == 0
          ? SingleChildScrollView(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  SizedBox(height: screenHeight / 2),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            } else if (snapshot.hasError) {
              return Column(
                children: [
                  SizedBox(height: screenHeight),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            } else {
              if (snapshot.data != null) {
                List<Map<String, dynamic>>? data = snapshot.data;
                if (data!.isEmpty) {
                  if (!displayAllCards) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight),
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Glückwunsch. Keine Aufgaben mehr für heute',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Noch keine Karteikarten hinzugefügt.Um eine neue Lern-Management Karte zu erstellen drücken Sie den Knopf unten Rechts',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                } else {
                  // Filter data based on the search query
                  List<Map<String, dynamic>> filteredData = data.where((row) {
                    return _searchQuery.isEmpty ||
                        row['thema'].toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  return StaggeredGrid.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    children: List.generate(filteredData.length, (index) {
                      Map<String, dynamic> row = filteredData[index];
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            if (selectedItems.contains(row['id'])) {
                              selectedItems.remove(row['id']);
                            } else {
                              selectedItems.add(row['id']);
                            }
                          });
                        },
                        onTap: () {
                          if (selectedItems.isNotEmpty) {
                            setState(() {
                              if (selectedItems.contains(row['id'])) {
                                selectedItems.remove(row['id']);
                              } else {
                                selectedItems.add(row['id']);
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditPage(row['id'])),
                            ).then((_) {
                              setState(() {
                                _dataFuture = sortData(
                                    sortingMethod, displayAllCards);
                              });
                            });
                          }
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              color: selectedItems.contains(row['id'])
                                  ? getColorByRechtsgebiet(
                                  row['selectedOption'], context).withOpacity(0.5)
                                  : getColorByRechtsgebiet(
                                  row['selectedOption'], context),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8.0),
                                Text(
                                  '${row['thema']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${row['anzahl']} Karteikarten',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(color: Colors.black87),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Wiederholen am: ${getWiederholungsDate(row['dates'], row['times'])}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }
              } else {
                return Column(
                  children: [
                    SizedBox(height: screenHeight),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }
            }
          },
        ),
      )
          : const CalendarPage(),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPage(9)),
          ).then((_) {
            setState(() {
              _dataFuture = sortData(sortingMethod, displayAllCards);
            });
          });
        },
        tooltip: 'Neuen Stapel hinzufügen',
        child: const Icon(Icons.add),
      )
          : null,
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                children: [
                  const Text('Karteikarten Übersicht'),
                  const SizedBox(
                      height: 10), // Add some space between text and image
                  Image.asset(
                    "lib/assets/icon.png",
                    width: 100, // Adjust width as needed
                    height: 100, // Adjust height as needed
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
              ),
              title: const Text('Einstellungen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                ).then((_) {
                  // This block executes after the SettingsPage is closed
                  setState(() {
                    _loadPrefs();
                  });
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.stacked_line_chart,
              ),
              title: const Text('Statistik'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsPage()),
                );
              },
            ),
            ExpansionTile(
              title: const Text('Sortieren nach'),
              leading: const Icon(Icons.sort),
              //childrenPadding: const EdgeInsets.only(left: 8),
              children: [
                SortingRadio(
                  sortingType: 'dates',
                  currentSortingMethod: sortingMethod,
                  onSortingChanged: (value) async {
                    List<Map<String, dynamic>> sortedData =
                        await sortData(value!, displayAllCards);
                    setState(() {
                      _dataFuture = Future.value(sortedData);
                      _saveSortingMethod(value);
                    });
                  },
                ),
                SortingRadio(
                  sortingType: 'thema',
                  currentSortingMethod: sortingMethod,
                  onSortingChanged: (value) async {
                    List<Map<String, dynamic>> sortedData =
                        await sortData(value!, displayAllCards);
                    setState(() {
                      _dataFuture = Future.value(sortedData);
                      _saveSortingMethod(value);
                    });
                  },
                ),
                SortingRadio(
                  sortingType: 'anzahl',
                  currentSortingMethod: sortingMethod,
                  onSortingChanged: (value) async {
                    List<Map<String, dynamic>> sortedData =
                        await sortData(value!, displayAllCards);
                    setState(() {
                      _dataFuture = Future.value(sortedData);
                      _saveSortingMethod(value);
                    });
                  },
                ),
                SortingRadio(
                  sortingType: 'selectedOption',
                  currentSortingMethod: sortingMethod,
                  onSortingChanged: (value) async {
                    List<Map<String, dynamic>> sortedData =
                        await sortData(value!, displayAllCards);
                    setState(() {
                      _dataFuture = Future.value(sortedData);
                      _saveSortingMethod(value);
                    });
                  },
                ),
                SortingRadio(
                  sortingType: 'id',
                  currentSortingMethod: sortingMethod,
                  onSortingChanged: (value) async {
                    List<Map<String, dynamic>> sortedData =
                        await sortData(value!, displayAllCards);
                    setState(() {
                      _dataFuture = Future.value(sortedData);
                      _saveSortingMethod(value);
                    });
                  },
                ),
                // Repeat for other sorting options
              ],
            ),
            ListTile(
              leading: const Icon(Icons.view_list),
              title: Text(displayAllCards
                  ? 'Alle Karten anzeigen'
                  : 'Karten nur von heute anzeigen'),
              onTap: () {
                setState(() {
                  displayAllCards = !displayAllCards;
                  _dataFuture = sortData(sortingMethod, displayAllCards);
                });
                _prefs.setBool('displayAllCards', displayAllCards);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_outlined),
              title: const Text("Lernplan erstellen lassen"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Lernplan erstellen"),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                TextFormField(
                                  readOnly: true,
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    labelText: "Alles wiederholen bis",
                                  ),
                                  onTap: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        timeFrame = pickedDate;
                                        _dateController.text =
                                            dateFormat.format(pickedDate);
                                        stapelPerDay = (dataLength /
                                                pickedDate
                                                    .difference(DateTime.now())
                                                    .inDays)
                                            .ceil();
                                      });
                                    }
                                  },
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Stapel pro Tag",
                                  ),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  // The validator receives the text that the user has entered.
                                  validator: (text) {
                                    if (amountPerDay < stapelPerDay) {
                                      return "Stapel pro Tag muss mindestens $stapelPerDay sein ";
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      // Update the amount per day variable
                                      amountPerDay = int.parse(value);
                                    });
                                  },
                                ),
                                ExpansionTile(
                                  title: const Text("Ruhetage wählen"),
                                  children: [
                                    const Divider(height: 0),
                                    Column(
                                      children: <Widget>[
                                        for (int i = 0; i < 7; i++)
                                          CheckboxListTile(
                                            value: selectedRestdays[i],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                selectedRestdays[i] = value!;
                                                updateDisabledDays(); // Call the function to update disabled days
                                              });
                                            },
                                            title: Text(getWeekdayName(i)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                ExpansionTile(
                                  title: const Text("Zivilrecht Tage wählen"),
                                  children: [
                                    const Divider(height: 0),
                                    Column(
                                      children: <Widget>[
                                        for (int i = 0; i < 7; i++)
                                          CheckboxListTile(
                                            value: selectedZRdays[i],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (!disabledDays[0][i]) {
                                                  selectedZRdays[i] = value!;
                                                }
                                              });
                                            },
                                            title: Text(
                                              getWeekdayName(i),
                                              style: TextStyle(
                                                decoration: disabledDays[0][i]
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: disabledDays[0][i]
                                                    ? Colors.grey[700]!
                                                    : null,
                                              ),
                                            ),
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                ExpansionTile(
                                  title: const Text("Ö-Recht Tage wählen"),
                                  children: [
                                    const Divider(height: 0),
                                    Column(
                                      children: <Widget>[
                                        for (int i = 0; i < 7; i++)
                                          CheckboxListTile(
                                            value: selectedOERdays[i],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (!disabledDays[0][i]) {
                                                  selectedOERdays[i] = value!;
                                                }
                                              });
                                            },
                                            title: Text(
                                              getWeekdayName(i),
                                              style: TextStyle(
                                                decoration: disabledDays[0][i]
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: disabledDays[0][i]
                                                    ? Colors.grey[700]!
                                                    : null,
                                              ),
                                            ),
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                ExpansionTile(
                                  title: const Text("Strafrecht Tage wählen"),
                                  children: [
                                    const Divider(height: 0),
                                    Column(
                                      children: <Widget>[
                                        for (int i = 0; i < 7; i++)
                                          CheckboxListTile(
                                            value: selectedSRdays[i],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (!disabledDays[0][i]) {
                                                  selectedSRdays[i] = value!;
                                                }
                                              });
                                            },
                                            title: Text(
                                              getWeekdayName(i),
                                              style: TextStyle(
                                                decoration: disabledDays[0][i]
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: disabledDays[0][i]
                                                    ? Colors.grey[700]!
                                                    : null,
                                              ),
                                            ),
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            selectedRestdays =
                                List.generate(7, (index) => false);
                            selectedZRdays = List.generate(7, (index) => false);
                            selectedOERdays =
                                List.generate(7, (index) => false);
                            selectedSRdays = List.generate(7, (index) => false);
                            _dateController.text = "";
                            Navigator.of(context).pop();
                          },
                          child: const Text("Abbrechen"),
                        ),
                        TextButton(
                          onPressed: () {
                            List<String> selectedRestDays = [
                              for (int i = 0; i < selectedRestdays.length; i++)
                                if (selectedRestdays[i]) getWeekdayName(i)
                            ];
                            List<String> zrDays = [
                              for (int i = 0; i < selectedZRdays.length; i++)
                                if (selectedZRdays[i]) getWeekdayName(i)
                            ];
                            List<String> oerDays = [
                              for (int i = 0; i < selectedOERdays.length; i++)
                                if (selectedOERdays[i]) getWeekdayName(i)
                            ];
                            List<String> srDays = [
                              for (int i = 0; i < selectedSRdays.length; i++)
                                if (selectedSRdays[i]) getWeekdayName(i)
                            ];
                            createStudyPlan(timeFrame, amountPerDay,
                                selectedRestDays, zrDays, oerDays, srDays);
                            _dataFuture =
                                sortData(sortingMethod, displayAllCards);
                            selectedRestdays =
                                List.generate(7, (index) => false);
                            selectedZRdays = List.generate(7, (index) => false);
                            selectedOERdays =
                                List.generate(7, (index) => false);
                            selectedSRdays = List.generate(7, (index) => false);
                            _dateController.text = "";
                            Navigator.of(context).pop();
                          },
                          child: const Text("Erstellen"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Kalender',
          ),
        ],
      ),
    );
  }
}
