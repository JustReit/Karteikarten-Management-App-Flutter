import 'package:flutter/material.dart';
import 'package:karteikarten_manager/service/constants.dart';
import 'package:karteikarten_manager/service/functions.dart';

Widget buildLine(Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(
      width: double.infinity, // Set width to match the whole screen width
      height: 3, // Set height to 5
      color: color,
    ),
  );
}

Widget buildTitle(String titleText) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
    child: Row(
      children: [
        Text(
          titleText,
          style: const TextStyle(
            fontSize: 18, // Adjust font size as needed
            fontWeight: FontWeight.w500, // Make it slightly bold
          ),
        ),
      ],
    ),
  );
}

Widget buildRow(BuildContext context, TextEditingController dateController,
    TextEditingController timeController, TextEditingController rechtsController,
    String labelText1, String labelText2, bool rechts, String selectedRestDay) {

  return Row(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            readOnly: false,
            controller: dateController,
            decoration: InputDecoration(
              labelText: labelText1,
              hintText: labelText1,
              border: const OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.always,
            validator: (text) {
              if (!isDateFormat(text) && text!.isNotEmpty) {
                return 'Format: dd.MM.yy';
              }
              return null;
            },
            onTap: () async {
              // Show DatePicker when the input is tapped
              final pickedDate = await showDatePicker(
                context: context,
                locale: const Locale("de", "DE"),
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                if (isRestday(pickedDate, selectedRestDay)) {
                   var snackBar = SnackBar(
                    content: Text('${dateFormat.format(pickedDate)} ist ein $selectedRestDay und damit ein Pausentag'),
                    duration: const Duration(seconds:5),
                  );
                  // Get the context of the nearest Scaffold and show the SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }

                dateController.text =
                    dateFormat.format(pickedDate); // Format the picked date
              }
            },
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            readOnly: false,
            controller: timeController,
            decoration: InputDecoration(
              labelText: labelText2,
              hintText: labelText2,
              border: const OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.always,
            validator: (text) {
              if (!isTimeFormat(text)&& text!.isNotEmpty) {
                return 'Format: hh:mm';
              }
              return null;
            },
            onTap: () async {
              // Show TimePicker when the input is tapped
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 0, minute: 0),
                cancelText: "Zurück",
                confirmText: "Speichern",
                hourLabelText: "Stunden",
                minuteLabelText: "Minuten",
                helpText: "Zeit auswählen",
                initialEntryMode:TimePickerEntryMode.input,
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        alwaysUse24HourFormat: true,
                      ),
                      child: child!,
                    ),
                  );
                },
              );
              if (pickedTime != null) {
                // Format the picked time and set it in the text field
                final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                timeController.text = formattedTime;
              }
            },
          ),
        ),
      ),
      if (rechts)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: rechtsController,
              decoration: const InputDecoration(
                labelText: 'Rechts',
                border: OutlineInputBorder(),
              ),
              keyboardType:
              TextInputType.number,
            ),
          ),
        ),
    ],
  );

}


