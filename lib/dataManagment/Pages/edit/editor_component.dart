import 'package:P2pChords/dataManagment/Pages/edit/style.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

class ChordEditorComponent extends StatefulWidget {
  final LyricLine line;
  final String songKey;
  final Function(LyricLine) onLineChanged;

  const ChordEditorComponent({
    Key? key,
    required this.line,
    required this.songKey,
    required this.onLineChanged,
  }) : super(key: key);

  @override
  State<ChordEditorComponent> createState() => _ChordEditorComponentState();
}

class _ChordEditorComponentState extends State<ChordEditorComponent> {
  late TextEditingController _lyricsController;
  late double _fontSize;
  bool _isDraggingChord = false;
  int? _selectedChordIndex;

  @override
  void initState() {
    super.initState();
    _lyricsController = TextEditingController(text: widget.line.lyrics);
    _fontSize = 16.0;
  }

  @override
  void dispose() {
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChordEditorComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) {
      _lyricsController.text = widget.line.lyrics;
    }
  }

  void _addChordAtPosition(int position) {
    final updatedChords = List<Chord>.from(widget.line.chords);
    updatedChords.add(Chord(position: position, value: "1"));
    updatedChords.sort((a, b) => a.position.compareTo(b.position));

    final updatedLine = LyricLine(
      lyrics: widget.line.lyrics,
      chords: updatedChords,
    );

    widget.onLineChanged(updatedLine);
  }

  void _updateChordPosition(int chordIndex, int newPosition) {
    if (newPosition < 0) newPosition = 0;
    if (newPosition > widget.line.lyrics.length) {
      newPosition = widget.line.lyrics.length;
    }

    final updatedChords = List<Chord>.from(widget.line.chords);
    final chord = updatedChords[chordIndex];
    updatedChords[chordIndex] =
        Chord(position: newPosition, value: chord.value);

    final updatedLine = LyricLine(
      lyrics: widget.line.lyrics,
      chords: updatedChords,
    );

    widget.onLineChanged(updatedLine);
  }

  void _updateLyrics(String newLyrics) {
    // Adjust chord positions if lyrics become shorter
    final updatedChords = List<Chord>.from(widget.line.chords);
    for (int i = 0; i < updatedChords.length; i++) {
      if (updatedChords[i].position > newLyrics.length) {
        updatedChords[i] =
            Chord(position: newLyrics.length, value: updatedChords[i].value);
      }
    }

    final updatedLine = LyricLine(
      lyrics: newLyrics,
      chords: updatedChords,
    );

    widget.onLineChanged(updatedLine);
  }

  void _editChord(int index) {
    final chord = widget.line.chords[index];
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: chord.value);
        return AlertDialog(
          title: const Text('Edit Chord'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration:
                    UIStyle.inputDecoration('Chord Value (e.g., 1, 4, -6)'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Preview: ${ChordUtils.nashvilleToChord(controller.text, widget.songKey)}',
                style: TextStyle(
                  color: UIStyle.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: UIStyle.secondaryButton,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: UIStyle.button,
              onPressed: () {
                final updatedChords = List<Chord>.from(widget.line.chords);
                updatedChords[index] =
                    Chord(position: chord.position, value: controller.text);

                final updatedLine = LyricLine(
                  lyrics: widget.line.lyrics,
                  chords: updatedChords,
                );

                widget.onLineChanged(updatedLine);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteChord(int index) {
    final updatedChords = List<Chord>.from(widget.line.chords)..removeAt(index);

    final updatedLine = LyricLine(
      lyrics: widget.line.lyrics,
      chords: updatedChords,
    );

    widget.onLineChanged(updatedLine);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual chord editor
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(UIStyle.spacing),
          decoration: BoxDecoration(
            color: UIStyle.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: UIStyle.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chords line (visual representation)
              Container(
                height: 32,
                margin: const EdgeInsets.only(bottom: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Positions for placing new chords (transparent overlay)
                    GestureDetector(
                      onTapUp: (details) {
                        // Calculate position in text where user tapped
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final position = _getPositionFromX(
                          details.localPosition.dx,
                          widget.line.lyrics,
                        );
                        _addChordAtPosition(position);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 32,
                        color: Colors.transparent,
                      ),
                    ),

                    // Existing chords
                    ...widget.line.chords.asMap().entries.map((entry) {
                      final index = entry.key;
                      final chord = entry.value;
                      final chordText = ChordUtils.nashvilleToChord(
                          chord.value, widget.songKey);

                      // Position chord at its location
                      final xPosition =
                          _getXFromPosition(chord.position, widget.line.lyrics);

                      return Positioned(
                        left: xPosition,
                        child: GestureDetector(
                          onTap: () => _editChord(index),
                          onPanStart: (_) {
                            setState(() {
                              _isDraggingChord = true;
                              _selectedChordIndex = index;
                            });
                          },
                          onPanUpdate: (details) {
                            if (_isDraggingChord &&
                                _selectedChordIndex == index) {
                              final RenderBox box =
                                  context.findRenderObject() as RenderBox;
                              final position = _getPositionFromX(
                                details.localPosition.dx,
                                widget.line.lyrics,
                              );
                              _updateChordPosition(index, position);
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
                                vertical: 2, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _selectedChordIndex == index
                                  ? UIStyle.primary
                                  : UIStyle.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  chordText,
                                  style: TextStyle(
                                    fontSize: _fontSize - 2,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedChordIndex == index
                                        ? Colors.white
                                        : UIStyle.primary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _deleteChord(index),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: _selectedChordIndex == index
                                        ? Colors.white
                                        : UIStyle.primary,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Lyrics with measurement marks to align with chords
              TextField(
                controller: _lyricsController,
                onChanged: _updateLyrics,
                style: TextStyle(fontSize: _fontSize),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Enter lyrics here',
                  hintStyle: TextStyle(
                    fontSize: _fontSize,
                    color: UIStyle.textLight.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chord controls legend
        Padding(
          padding: EdgeInsets.only(top: UIStyle.smallSpacing),
          child: RichText(
            text: const TextSpan(
              style: UIStyle.caption,
              children: const [
                TextSpan(text: '• '),
                TextSpan(
                  text: 'Tap',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' line to add chord, '),
                TextSpan(
                  text: 'drag',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' chord to reposition, '),
                TextSpan(
                  text: 'tap',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' chord to edit'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get X position from character position
  double _getXFromPosition(int position, String text) {
    if (position <= 0) return 0;
    if (position >= text.length) {
      // Measure full text width
      return _getTextWidth(text, _fontSize);
    }

    // Measure substring width
    return _getTextWidth(text.substring(0, position), _fontSize);
  }

  // Helper method to get character position from X coordinate
  int _getPositionFromX(double x, String text) {
    if (x <= 0) return 0;

    final fullWidth = _getTextWidth(text, _fontSize);
    if (x >= fullWidth) return text.length;

    // Binary search for closest position
    int low = 0;
    int high = text.length;

    while (low < high) {
      int mid = (low + high) ~/ 2;
      double width = _getTextWidth(text.substring(0, mid), _fontSize);

      if (width < x) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  // Helper to get text width
  double _getTextWidth(String text, double fontSize) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}
