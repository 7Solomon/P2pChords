import 'dart:convert';
import 'dart:math';
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';

/// A reusable widget for editing chords visually
class ChordEditor extends StatefulWidget {
  final String chordText;
  final Function(String) onTextChanged;
  final Color accentColor;
  final bool showTextField;
  final double fontSize;
  final String songKey;
  final String? lyricsRefrence;

  const ChordEditor({
    super.key,
    required this.chordText,
    required this.onTextChanged,
    required this.fontSize,
    this.accentColor = Colors.amber,
    this.showTextField = true,
    this.songKey = '',
    this.lyricsRefrence,
  });

  @override
  State<ChordEditor> createState() => _ChordEditorState();
}

class _ChordEditorState extends State<ChordEditor> {
  final SongConverter converter = SongConverter();
  List<Chord> _chords = [];
  bool _isDraggingChord = false;
  double? _dragStartX;
  int? _initialChordPosition;
  int? _selectedChordIndex;
  String? _songKey;

  @override
  void initState() {
    super.initState();
    _songKey = widget.songKey;
    _parseChords();
  }

  @override
  void didUpdateWidget(ChordEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chordText != widget.chordText) {
      _parseChords();
    }

    if (oldWidget.songKey != widget.songKey) {
      _songKey = widget.songKey;
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Parse chord text into positions and values
  void _parseChords() {
    _chords = [];

    // Find all chord positions and values using regex
    final chordMatches = RegExp(r'(\S+)').allMatches(widget.chordText);
    print(widget.chordText);
    print(widget.lyricsRefrence);
    for (var match in chordMatches) {
      final chordValue = match.group(0)!;
      final position = match.start;
      print({
        'chordValue': chordValue,
        'position': position,
      });
      _chords.add(Chord(position: position, value: chordValue));
    }
  }

  // Convert parsed chords back to chord line text
  String _chordsToText() {
    if (_chords.isEmpty) return '';

    // Sort chords by position
    _chords.sort((a, b) => a.position.compareTo(b.position));

    // Create a string with spaces at appropriate positions
    String result = '';
    int lastPos = 0;

    for (var chord in _chords) {
      // Add spaces to reach the chord position
      while (lastPos < chord.position) {
        result += ' ';
        lastPos++;
      }

      // Add the chord
      result += chord.value;
      lastPos += chord.value.length;
    }

    return result;
  }

  // Add a new chord at the specified position
  void _addChordAtPosition(int position) {
    // Check if position is already occupied by another chord
    for (var chord in _chords) {
      int chordEndPos = chord.position + chord.value.length;
      if (position >= chord.position && position < chordEndPos) {
        // Position is inside an existing chord, don't add a new one
        return;
      }
    }

    setState(() {
      _chords.add(Chord(position: position, value: 'C'));
      _updateChordLine();
    });
  }

  // Update chord position when dragging
  void _updateChordPosition(int chordIndex, int newPosition) {
    if (newPosition < 0) newPosition = 0;

    // Check if the new position conflicts with other chords
    final movingChord = _chords[chordIndex];
    final chordWidth = movingChord.value.length;
    //print('Moving chord: ${movingChord.value} to $newPosition');
    for (int i = 0; i < _chords.length; i++) {
      if (i == chordIndex) continue; // Skip the chord being moved

      final otherChord = _chords[i];
      final otherChordEnd = otherChord.position + otherChord.value.length;

      // Check for collision (simplified logic to avoid positioning bugs)
      if ((newPosition >= otherChord.position && newPosition < otherChordEnd) ||
          (newPosition + chordWidth > otherChord.position &&
              newPosition < otherChord.position)) {
        // Position would overlap with another chord
        return;
      }
    }

    setState(() {
      _chords[chordIndex] = _chords[chordIndex].copyWith(position: newPosition);
      _updateChordLine();
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

  // Update the chord line text
  void _updateChordLine() {
    final newChordText = _chordsToText();
    //_textController.text = newChordText;
    widget.onTextChanged(newChordText);
  }

  // Calculate width for the chord editor
  double _calculateTextWidth(int characters) {
    if (characters <= 0) return 300;
    double charWidth = 9.5; // Approximate width of monospace character
    double estimatedWidth = characters * charWidth + 50; // Add padding
    return max(estimatedWidth, 300); // Minimum width of 300
  }

  // Get X position from character position
  double _getXFromPosition(int position) {
    if (position <= 0) return 0;
    return position * 9.5;
  }

  // Get character position from X coordinate
  int _getPositionFromX(double x) {
    if (x <= 0) return 0;
    return (x / 9.5).round();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.accentColor;
    final Color lightColor = widget.accentColor.withOpacity(0.2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _calculateTextWidth(widget.chordText.length + 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chords line with visual positioning
            SizedBox(
              height: 40, // Increased height to accommodate Nashville notation
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background for tapping to add chords
                  GestureDetector(
                    onTapUp: (details) {
                      final position =
                          _getPositionFromX(details.localPosition.dx);
                      _addChordAtPosition(position);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      color: Colors.transparent,
                    ),
                  ),

                  // Display existing chords
                  ..._chords.asMap().entries.map((entry) {
                    final index = entry.key;
                    final chord = entry.value;
                    final xPosition = _getXFromPosition(chord.position);
                    final isSelected = _selectedChordIndex == index;

                    // Get Nashville notation for this chord
                    String nashville = "";
                    //print(_songKey);
                    if (_songKey != null && _songKey!.isNotEmpty) {
                      try {
                        nashville =
                            ChordUtils.chordToNashville(chord.value, _songKey!);
                      } catch (e) {
                        nashville = "?";
                        //print('Error converting to Nashville: $e');
                      }
                    }

                    return Positioned(
                      left: xPosition,
                      child: GestureDetector(
                        onTap: () => _editChord(index),
                        onLongPress: () => _deleteChord(index),
                        onPanStart: (details) {
                          setState(() {
                            _isDraggingChord = true;
                            _selectedChordIndex = index;
                            _dragStartX = details.localPosition.dx;
                            _initialChordPosition = chord.position;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isDraggingChord &&
                              _selectedChordIndex == index) {
                            // Calculate delta movement
                            final deltaX =
                                details.localPosition.dx - _dragStartX!;

                            // Convert pixel movement to character position change
                            final charDelta = (deltaX / 9.5)
                                .round(); // Using your existing character width

                            // Apply delta to original position
                            final newPosition =
                                _initialChordPosition! + charDelta;
                            _updateChordPosition(index, newPosition);
                          }
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _isDraggingChord = false;
                            _selectedChordIndex = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : lightColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isSelected
                                ? [
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chord value
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: chord.value,
                                      style: TextStyle(
                                        fontSize: widget.fontSize - 2,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: nashville,
                                      style: TextStyle(
                                        fontSize: (widget.fontSize - 2) *
                                            0.7, // Smaller font for subscript
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                        fontFeatures: const [
                                          FontFeature.subscripts()
                                        ],
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
