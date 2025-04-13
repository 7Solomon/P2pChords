// Add this after your existing widgets

import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

/// Widget for validating and previewing the key input
class KeyInputPreview extends StatefulWidget {
  final TextEditingController keyController;
  final PreliminarySongData songData;
  final Function(String) onKeyChanged;

  const KeyInputPreview({
    super.key,
    required this.keyController,
    required this.songData,
    required this.onKeyChanged,
  });

  @override
  State<KeyInputPreview> createState() => _KeyInputPreviewState();
}

class _KeyInputPreviewState extends State<KeyInputPreview> {
  bool isValidKey = false;
  int validChordCount = 0;
  int totalChordCount = 0;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    widget.keyController.addListener(_validateKey);
  }

  @override
  void dispose() {
    widget.keyController.removeListener(_validateKey);
    super.dispose();
  }

  void _validateKey() {
    final keyValue = widget.keyController.text.trim();
    widget.onKeyChanged(keyValue);

    if (keyValue.isEmpty) {
      setState(() {
        isValidKey = false;
        errorMessage = '';
      });
      return;
    }

    // Validate key format (A-G with optional # or b)
    final validKeyFormat = RegExp(r'^[A-G][#b]?$').hasMatch(keyValue);

    if (!validKeyFormat) {
      setState(() {
        isValidKey = false;
        errorMessage = 'Invalid key format. Use A-G with optional # or b';
      });
      return;
    }

    // Count how many chords we can successfully parse
    int validChords = 0;
    int totalChords = 0;

    for (var section in widget.songData.sections) {
      for (var line in section.lines) {
        if (line.isChordLine) {
          // Find all chords in the line
          final chordMatches =
              RegExp(r'([A-G][#b]?\w*(?:\*)?|N\.C\.)').allMatches(line.text);

          for (var match in chordMatches) {
            totalChords++;

            // Try to parse as Nashville
            try {
              final chordText = match.group(0)!;
              // If this doesn't throw an error, it's a valid chord
              ChordUtils.chordToNashville(chordText, keyValue);
              validChords++;
            } catch (e) {
              // Invalid chord for this key
            }
          }
        }
      }
    }

    setState(() {
      isValidKey = validKeyFormat;
      validChordCount = validChords;
      totalChordCount = totalChords;
      errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.keyController,
          decoration: InputDecoration(
            labelText: 'Song Key',
            border: const OutlineInputBorder(),
            hintText: 'e.g. A, C#, Bb',
            suffixIcon: isValidKey
                ? const Icon(Icons.check, color: Colors.green)
                : widget.keyController.text.isNotEmpty
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
          ),
        ),

        // Status message
        if (widget.keyController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: isValidKey
                ? Text(
                    'Valid key: $validChordCount of $totalChordCount chords recognized',
                    style: TextStyle(
                      color: validChordCount == totalChordCount
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 12,
                    ),
                  )
                : Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
          ),

        // Show available keys
        if (widget.keyController.text.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              'Valid keys: A, A#/Bb, B, C, C#/Db, D, D#/Eb, E, F, F#/Gb, G, G#/Ab',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
