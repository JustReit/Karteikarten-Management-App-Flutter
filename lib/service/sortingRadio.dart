import 'package:flutter/material.dart';

class SortingRadio extends StatefulWidget {
  final String sortingType;
  final String currentSortingMethod;
  final void Function(String?)? onSortingChanged;

  SortingRadio({
    required this.sortingType,
    required this.currentSortingMethod,
    required this.onSortingChanged,
  });

  @override
  _SortingRadioState createState() => _SortingRadioState();
}

class _SortingRadioState extends State<SortingRadio> {
  late String _currentSortingMethod;

  @override
  void initState() {
    super.initState();
    _currentSortingMethod = widget.currentSortingMethod;
  }

  @override
  void didUpdateWidget(SortingRadio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSortingMethod != _currentSortingMethod) {
      setState(() {
        _currentSortingMethod = widget.currentSortingMethod;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.sortingType == 'dates'
            ? 'Datum'
            : widget.sortingType == 'thema'
            ? 'Thema'
            : widget.sortingType == 'anzahl'
            ? 'Anzahl'
            : widget.sortingType == 'selectedOption'
            ? 'Rechtsgebiet'
            : 'Hinzugefügt am',
      ),
      leading: Radio<String>(
        value: widget.sortingType,
        groupValue: _currentSortingMethod, // Use local state here
        onChanged: widget.onSortingChanged,
      ),
      onTap: () {
        widget.onSortingChanged!(widget.sortingType);
      },
    );
  }
}
