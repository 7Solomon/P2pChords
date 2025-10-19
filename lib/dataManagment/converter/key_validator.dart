import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/converter/classes.dart';
import 'package:flutter/material.dart';

class KeyInputPreview extends StatefulWidget {
  final TextEditingController keyController;
  final PreliminarySongData songData;
  final Function(String) onKeyChanged;
  final bool showKeyDetection;

  const KeyInputPreview({
    super.key,
    required this.keyController,
    required this.songData,
    required this.onKeyChanged,
    this.showKeyDetection = true,
  });

  @override
  State<KeyInputPreview> createState() => _KeyInputPreviewState();
}

class _KeyInputPreviewState extends State<KeyInputPreview> {
  bool isValidKey = false;
  int validChordCount = 0;
  int totalChordCount = 0;
  String errorMessage = '';
  List<String> detectedKeys = [];
  bool isDetectingKey = false;

  @override
  void initState() {
    super.initState();
    widget.keyController.addListener(_validateKey);
    // Auto-detect key if no key is set initially
    if (widget.keyController.text.trim().isEmpty && widget.showKeyDetection) {
      _detectPossibleKeys();
    }
  }

  @override
  void dispose() {
    widget.keyController.removeListener(_validateKey);
    super.dispose();
  }

  // Detect possible keys by testing all available keys against the song's chords
  void _detectPossibleKeys() {
    if (isDetectingKey) return;

    setState(() {
      isDetectingKey = true;
      detectedKeys.clear();
    });

    // Get all chords from the song
    Set<String> allChords = {};
    for (var section in widget.songData.sections) {
      for (var line in section.lines) {
        if (line.isChordLine) {
          final chords = ChordUtils.extractChordsFromLine(line.text);
          allChords.addAll(chords);
        }
      }
    }

    if (allChords.isEmpty) {
      setState(() {
        isDetectingKey = false;
      });
      return;
    }

    // Test each available key
    Map<String, int> keyScores = {};
    final availableKeys = ChordUtils.availableKeys;

    for (String testKey in availableKeys) {
      int validChordsForKey = 0;
      for (String chord in allChords) {
        try {
          ChordUtils.chordToNashville(chord, testKey);
          validChordsForKey++;
        } catch (e) {
          // Chord is not valid for this key
        }
      }

      if (validChordsForKey > 0) {
        keyScores[testKey] = validChordsForKey;
      }
    }

    // Sort keys by score (descending) and take top matches
    var sortedKeys = keyScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Only keep keys that parse all or most chords successfully
    final maxScore = sortedKeys.isNotEmpty ? sortedKeys.first.value : 0;
    final threshold = (allChords.length * 0.8)
        .ceil(); // At least 80% of chords should be valid

    setState(() {
      detectedKeys = sortedKeys
          .where((entry) => entry.value >= threshold || entry.value == maxScore)
          .take(3) // Show top 3 candidates
          .map((entry) => entry.key)
          .toList();
      isDetectingKey = false;
    });
  }

  void _validateKey() {
    final keyValue = widget.keyController.text.trim();
    widget.onKeyChanged(keyValue);

    // Count total chords first (even when no key is set)
    int totalChords = 0;
    for (var section in widget.songData.sections) {
      for (var line in section.lines) {
        if (line.isChordLine) {
          final chords = ChordUtils.extractChordsFromLine(line.text);
          totalChords += chords.length;
        }
      }
    }

    if (keyValue.isEmpty) {
      setState(() {
        isValidKey = false;
        validChordCount = 0;
        totalChordCount = totalChords;
        errorMessage = '';
      });

      // Auto-trigger key detection if we have chords but no detected keys yet
      if (totalChords > 0 &&
          detectedKeys.isEmpty &&
          widget.showKeyDetection &&
          !isDetectingKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _detectPossibleKeys();
        });
      }
      return;
    }

     // Validate key format (A-G with optional # or b, and optional 'm' for minor)
    final validKeyFormat = RegExp(r'^[A-G][#b]?m?$').hasMatch(keyValue);


    if (!validKeyFormat) {
      setState(() {
        isValidKey = false;
        validChordCount = 0;
        totalChordCount = totalChords;
        errorMessage = 'Invalid format. Use C, C#m, Bb, etc.';
      });
      return;
    }

    // Count how many chords we can successfully parse
    int validChords = 0;
    for (var section in widget.songData.sections) {
      for (var line in section.lines) {
        if (line.isChordLine) {
          // Use ChordUtils to find and parse all chords in the line
          final chords = ChordUtils.extractChordsFromLine(line.text);

          for (String chordText in chords) {
            // Try to convert to Nashville - if successful, it's valid
            try {
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
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showKeyDetection &&
                    widget.keyController.text.trim().isEmpty)
                  IconButton(
                    icon: isDetectingKey
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high, size: 20),
                    onPressed: isDetectingKey ? null : _detectPossibleKeys,
                    tooltip: 'Auto-detect key from chords',
                  ),
                if (isValidKey)
                  const Icon(Icons.check, color: Colors.green)
                else if (widget.keyController.text.isNotEmpty)
                  const Icon(Icons.error, color: Colors.red),
              ],
            ),
          ),
        ),

        // Key detection results
        if (widget.showKeyDetection &&
            detectedKeys.isNotEmpty &&
            widget.keyController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Suggested Keys:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: detectedKeys
                          .map((key) => ActionChip(
                                label: Text(key),
                                onPressed: () {
                                  widget.keyController.text = key;
                                  widget.onKeyChanged(key);
                                },
                                backgroundColor: Colors.blue.shade100,
                                labelStyle:
                                    TextStyle(color: Colors.blue.shade800),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
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

        // Warning when no key is set
        if (widget.keyController.text.trim().isEmpty && totalChordCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No key set! Chords will be stored in original format. Set a key to enable Nashville notation, transposition, and better chord validation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
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
