import 'dart:convert';
import 'dart:math';
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/song_converter.dart';

// Function types remain the same
typedef GetXFromPosition = double Function(int position);
typedef GetPositionFromX = int Function(double dx);

class ChordEditor extends StatefulWidget {
  final String chordText;
  final Function(String) onTextChanged;
  final Color accentColor;
  final double fontSize;
  final String? songKey; // Make nullable

  // Make lyrics-dependent parameters nullable
  final GetXFromPosition? getXFromPosition;
  final GetPositionFromX? getPositionFromX;
  final double editorHeight;
  final int? lyricsLength;
  final double? requiredWidth; // Width needed for content alignment

  const ChordEditor({
    super.key,
    required this.chordText,
    required this.onTextChanged,
    required this.fontSize,
    this.getXFromPosition, // Not required
    this.getPositionFromX, // Not required
    this.lyricsLength, // Not required
    this.requiredWidth, // Not required
    this.accentColor = Colors.amber,
    this.songKey, // Not required
    this.editorHeight = 40.0,
  });

  @override
  State<ChordEditor> createState() => _ChordEditorState();
}

class _ChordEditorState extends State<ChordEditor> {
  List<Chord> _chords = [];
  bool _isDraggingChord = false;
  int? _selectedChordIndex;
  // Remove _songKey state variable, use widget.songKey directly
  // String? _songKey;

  Offset? _dragStartOffset;
  int? _dragStartChordPosition;

  // Define a fallback character width for standalone mode
  static const double _fallbackCharWidth =
      9.5; // Adjust as needed for your font

  @override
  void initState() {
    super.initState();
    // _songKey = widget.songKey; // No longer needed here
    _parseChords();
  }

  @override
  void didUpdateWidget(ChordEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chordText != widget.chordText) {
      _parseChords();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _parseChords() {
    _chords = [];
    if (widget.chordText.isEmpty) return; // Handle empty case

    final chordMatches = RegExp(r'(\S+)').allMatches(widget.chordText);
    // print("Parsing Chord Text: ${widget.chordText}");
    for (var match in chordMatches) {
      final chordValue = match.group(0)!;
      // Ensure position is non-negative, although match.start should be >= 0
      final position = max(0, match.start);
      // print({'chordValue': chordValue, 'position': position});
      _chords.add(Chord(position: position, value: chordValue));
    }
    // Sort immediately after parsing
    _chords.sort((a, b) => a.position.compareTo(b.position));
  }

  String _chordsToText() {
    if (_chords.isEmpty) return '';

    // Ensure chords are sorted before generating text
    _chords.sort((a, b) => a.position.compareTo(b.position));

    StringBuffer result = StringBuffer(); // More efficient for string building
    int lastPos = 0;

    for (var chord in _chords) {
      // Ensure non-negative position and handle potential overlaps after sorting
      final chordPos = max(0, chord.position);

      // If the current chord position is before or at the end of the last one,
      // add at least one space unless it's the very first character.
      if (chordPos < lastPos) {
        if (lastPos > 0) {
          result.write(' ');
          lastPos++;
        }
        // Place the chord at the adjusted lastPos
        result.write(chord.value);
        lastPos += chord.value.length;
      } else {
        // Add spaces to reach the chord position
        result.write(' ' * (chordPos - lastPos));
        result.write(chord.value);
        lastPos = chordPos + chord.value.length;
      }
    }
    return result.toString();
  }

  void _addChordAtPosition(int position) {
    // Clamp position to be non-negative
    position = max(0, position);
    const defaultChordValue = 'C'; // Example default chord
    final defaultChordLength = defaultChordValue.length;

    // Check for overlaps with existing chords
    for (var chord in _chords) {
      final chordStart = chord.position;
      final chordEnd = chordStart + chord.value.length;
      final newChordEnd = position + defaultChordLength;

      // Check if the new chord [position, newChordEnd) overlaps with [chordStart, chordEnd)
      if (position < chordEnd && newChordEnd > chordStart) {
        // print("Overlap detected: Cannot add chord at $position");
        return; // Don't add if overlap
      }
    }

    setState(() {
      _chords.add(Chord(position: position, value: defaultChordValue));
      // Keep sorted after adding
      // _chords.sort((a, b) => a.position.compareTo(b.position)); // Sorting happens in _chordsToText
      _updateChordLine(); // Update parent state
    });
  }

  void _updateChordPosition(int chordIndex, int newPosition) {
    // Clamp position to be non-negative and within reasonable bounds (optional upper bound)
    newPosition = max(0, newPosition);
    // Optional: Clamp based on lyricsLength if needed, e.g., newPosition = newPosition.clamp(0, widget.lyricsLength);

    final movingChord = _chords[chordIndex];
    final chordLength = movingChord.value.length;

    // Check for overlaps with other chords at the new position
    for (int i = 0; i < _chords.length; i++) {
      if (i == chordIndex) continue; // Skip self-comparison
      final otherChord = _chords[i];
      final otherStart = otherChord.position;
      final otherEnd = otherStart + otherChord.value.length;
      final newStart = newPosition;
      final newEnd = newStart + chordLength;

      // Check if the new range [newStart, newEnd) overlaps with [otherStart, otherEnd)
      if (newStart < otherEnd && newEnd > otherStart) {
        // print("Overlap detected: Cannot move ${movingChord.value} to $newPosition");
        return; // Prevent move if overlap
      }
    }

    // If no overlap, update the chord's position
    setState(() {
      _chords[chordIndex] = movingChord.copyWith(position: newPosition);
      // Keep sorted after moving
      // _chords.sort((a, b) => a.position.compareTo(b.position)); // Sorting happens in _chordsToText
      _updateChordLine(); // Update parent state
    });
  }

  // Edit a chord when tapped
  void _editChord(int index) {
    final chord = _chords[index];
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: chord.value);
        return AlertDialog(
          title: const Text('Edit Chord'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Chord Value',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _chords[index] = chord.copyWith(value: controller.text);
                  _updateChordLine();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Delete a chord
  void _deleteChord(int index) {
    setState(() {
      _chords.removeAt(index);
      _updateChordLine();
    });
  }

  void _updateChordLine() {
    final newChordText = _chordsToText();
    widget.onTextChanged(newChordText);
    // After updating text, the parent widget will rebuild this widget,
    // and didUpdateWidget will call _parseChords if necessary.
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.accentColor;
    final Color lightColor = widget.accentColor.withOpacity(0.2);
    final Color indicatorColor = Colors.grey.shade400;

    // Determine if running in standalone mode (no lyrics provided)
    final bool isStandalone = widget.getXFromPosition == null;

    // Define the positioning functions to use based on the mode
    final GetXFromPosition currentGetX = isStandalone
        ? (pos) => pos * _fallbackCharWidth // Use fixed width calculation
        : widget.getXFromPosition!;
    final GetPositionFromX currentGetPos = isStandalone
        ? (dx) => max(
            0, (dx / _fallbackCharWidth).round()) // Use fixed width calculation
        : widget.getPositionFromX!;

    // Calculate the width for the SizedBox based on the mode
    final double contentWidth = isStandalone
        // Calculate width based on chord text length and fallback width
        // Ensure a minimum width for usability when empty
        ? max(300.0, widget.chordText.length * _fallbackCharWidth + 50.0)
        : widget.requiredWidth!; // Use provided width if available

    return SizedBox(
      // Root is SizedBox
      width: contentWidth,
      height: widget.editorHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Tappable Area
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (details) {
                // Use the appropriate position function for the current mode
                final position = currentGetPos(details.localPosition.dx);

                _addChordAtPosition(position);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Character Position Indicators (Only show if lyrics are provided)
          if (!isStandalone && widget.lyricsLength != null)
            for (int i = 0; i <= widget.lyricsLength!; i++)
              Positioned(
                // Use the appropriate position function for the current mode
                left: currentGetX(i),
                top: widget.editorHeight * 0.6,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: indicatorColor,
                ),
              ),

          // Display Chords
          ..._chords.asMap().entries.map((entry) {
            final index = entry.key;
            final chord = entry.value;
            // Use the appropriate position function for the current mode
            final xPosition = currentGetX(chord.position);
            final isSelected = _selectedChordIndex == index;

            // Calculate Nashville only if songKey is provided
            String nashville = "";
            if (widget.songKey != null && widget.songKey!.isNotEmpty) {
              try {
                nashville =
                    ChordUtils.chordToNashville(chord.value, widget.songKey!);
              } catch (e) {
                nashville = "?";
              }
            }

            return Positioned(
              left: xPosition,
              top: 0,
              child: GestureDetector(
                onTap: () => _editChord(index),
                onLongPress: () => _deleteChord(index),
                onPanStart: (details) {
                  setState(() {
                    _isDraggingChord = true;
                    _selectedChordIndex = index;
                    _dragStartOffset = details.localPosition;
                    _dragStartChordPosition = chord.position;
                  });
                },
                onPanUpdate: (details) {
                  if (_isDraggingChord && _dragStartChordPosition != null) {
                    // Use appropriate functions for drag calculation
                    final originalX = currentGetX(_dragStartChordPosition!);
                    final currentDragX = originalX +
                        (details.localPosition.dx - _dragStartOffset!.dx);
                    final newPosition = currentGetPos(currentDragX);

                    if (newPosition != _chords[index].position) {
                      _updateChordPosition(index, newPosition);
                    }
                  }
                },
                onPanEnd: (_) {
                  if (_isDraggingChord) {
                    setState(() {/* ... reset state ... */});
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : lightColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.black54 : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isSelected ? [/* ... */] : null,
                  ),
                  child: RichText(
                    text: TextSpan(
                      // Default style for the entire span (can be overridden)
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontFamily: 'Roboto Mono',
                        color: isSelected ? Colors.white : Colors.black87,
                        height: 1.1, // Adjust line height if needed
                      ),
                      children: <TextSpan>[
                        // Main Chord Value
                        TextSpan(
                          text: chord.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, // Keep chord bold
                          ),
                        ),
                        // Nashville Chord (if available)
                        if (nashville.isNotEmpty)
                          TextSpan(
                            text: ' $nashville', // Add space before nashville
                            style: TextStyle(
                              fontSize: widget.fontSize * 0.75, // Smaller size
                              color: Colors.red.shade700, // Red color
                              fontWeight: FontWeight.normal, // Not bold
                              fontFeatures: const [
                                FontFeature.superscripts()
                              ], // maybe not bad
                            ),
                          ),
                      ],
                    ),
                    softWrap: false, // Prevent wrapping
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
