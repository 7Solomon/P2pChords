import 'package:flutter/material.dart';

class UIComponents {
  // Text field styling
  final OutlineInputBorder textFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.0),
    borderSide: BorderSide(color: Colors.blueGrey, width: 1.0),
  );

  // Button styling
  final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
    textStyle: TextStyle(fontSize: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // Card styling
  final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 15.0,
        spreadRadius: 1.0,
      ),
    ],
  );

  // List of common musical keys
  final List<String> musicalKeys = [
    'C',
    'C#/Db',
    'D',
    'D#/Eb',
    'E',
    'F',
    'F#/Gb',
    'G',
    'G#/Ab',
    'A',
    'A#/Bb',
    'B'
  ];

  // Key selection dropdown
  Widget keySelectionDropdown({
    required String selectedKey,
    required void Function(String?) onChanged,
    double width = 120,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blueGrey, width: 1.0),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: selectedKey,
            isExpanded: true,
            icon: const Icon(Icons.music_note),
            elevation: 16,
            style: TextStyle(color: Colors.blue.shade700),
            onChanged: onChanged,
            items: musicalKeys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Custom text field
  Widget customTextField(
    TextEditingController controller, {
    String labelText = '',
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: textFieldBorder,
        focusedBorder: textFieldBorder.copyWith(
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }

  // Custom button
  Widget customButton({
    required VoidCallback onPressed,
    required String text,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(text),
      ),
    );
  }
}

// singleton instance for easy access
final uiComponents = UIComponents();
