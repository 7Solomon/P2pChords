import 'package:P2pChords/dataManagment/converter/classes.dart';
import 'package:P2pChords/dataManagment/converter/components/chord_editor.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a chord-lyric pair
class ChordLyricPair extends StatefulWidget {
  final PreliminaryLine chordLine;
  final PreliminaryLine lyricLine;
  final int sectionIndex;
  final int chordLineIndex;
  final int lyricLineIndex;
  final Function(int, int, String) onUpdateLineText;
  final Function(int, int) onRemoveLine;
  final Function(int, int) onMoveLine;
  final Function(int, int) onSplitPair;
  final String songKey;

  const ChordLyricPair({
    super.key,
    required this.chordLine,
    required this.lyricLine,
    required this.sectionIndex,
    required this.chordLineIndex,
    required this.lyricLineIndex,
    required this.onUpdateLineText,
    required this.onRemoveLine,
    required this.onMoveLine,
    required this.onSplitPair,
    required this.songKey,
  });

  @override
  State<ChordLyricPair> createState() => _ChordLyricPairState();
}

class _ChordLyricPairState extends State<ChordLyricPair> {
  late TextEditingController _lyricController;
  final TextPainter _lyricTextPainter =
      TextPainter(textDirection: TextDirection.ltr);
  final TextStyle _lyricStyle =
      const TextStyle(fontSize: 14, height: 1.0, fontFamily: 'Roboto Mono');
  static const double _textFieldHorizontalPadding = 12.0;

  // Create a ScrollController
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _lyricController = TextEditingController(text: widget.lyricLine.text);
    _scrollController = ScrollController(); // Initialize the controller
    _updateTextPainter();
  }

  @override
  void dispose() {
    _lyricController.dispose();
    _scrollController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  void didUpdateWidget(ChordLyricPair oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsPainterUpdate = false;
    if (oldWidget.lyricLine.text != widget.lyricLine.text) {
      // Update controller only if text actually changed externally
      if (_lyricController.text != widget.lyricLine.text) {
        _lyricController.text = widget.lyricLine.text;
        // Move cursor to end after programmatic change
        _lyricController.selection = TextSelection.fromPosition(
          TextPosition(offset: _lyricController.text.length),
        );
      }
      needsPainterUpdate = true;
    }
    // Add check for style changes if applicable
    // if (oldWidget._lyricStyle != _lyricStyle) { // Example
    //   needsPainterUpdate = true;
    // }

    if (needsPainterUpdate) {
      // Ensure painter is updated *before* potentially using its metrics
      _updateTextPainter();
    }
  }

  void _updateTextPainter() {
    _lyricTextPainter.text =
        TextSpan(text: widget.lyricLine.text, style: _lyricStyle);
    // Layout with constraints. Use a large width to avoid premature wrapping.
    _lyricTextPainter.layout(maxWidth: double.infinity);
    // print("TextPainter laid out: width=${_lyricTextPainter.width}, height=${_lyricTextPainter.height}");
  }

  void _updateChordText(String newText) {
    widget.onUpdateLineText(
      widget.sectionIndex,
      widget.chordLineIndex,
      newText,
    );
  }

  void _updateLyrics(String newLyrics) {
    widget.onUpdateLineText(
      widget.sectionIndex,
      widget.lyricLineIndex,
      newLyrics,
    );
    // Update the TextPainter immediately as lyrics change in the TextField
    setState(() {
      _updateTextPainter();
    });
  }

  // Function to pass to ChordEditor: Gets X offset *within the ChordEditor's Stack*
  double _getLyricXFromPosition(int position) {
    // Ensure painter has been laid out, especially important during initial build
    if (_lyricTextPainter.width == 0.0 && widget.lyricLine.text.isNotEmpty) {
      // print("Warning: TextPainter not laid out in _getLyricXFromPosition. Forcing layout.");
      _updateTextPainter(); // Force layout if needed
    }
    if (_lyricTextPainter.text == null){
      return _textFieldHorizontalPadding; // Return padding if no text
    }
    final textLength = _lyricTextPainter.text!.toPlainText().length;
    final clampedPosition = position.clamp(0, textLength);

    // Calculate offset based on TextPainter
    final textOffset = _lyricTextPainter
        .getOffsetForCaret(TextPosition(offset: clampedPosition), Rect.zero)
        .dx;

    // Add the TextField's left padding to align with the visual text start
    return textOffset + _textFieldHorizontalPadding;
  }

  // Function to pass to ChordEditor: Gets character position from X offset *within the ChordEditor's Stack*
  int _getLyricPositionFromX(double dx) {
    // Ensure painter has been laid out
    if (_lyricTextPainter.width == 0.0 && widget.lyricLine.text.isNotEmpty) {
      // print("Warning: TextPainter not laid out in _getLyricPositionFromX. Forcing layout.");
      _updateTextPainter(); // Force layout if needed
    }
    if (_lyricTextPainter.text == null) return 0;

    // Adjust the dx by subtracting the TextField's left padding
    final adjustedDx = (dx - _textFieldHorizontalPadding).clamp(
        0.0, _lyricTextPainter.width); // Clamp to valid text painter range

    final position =
        _lyricTextPainter.getPositionForOffset(Offset(adjustedDx, 0));
    final textLength = _lyricTextPainter.text!.toPlainText().length;

    // Clamp the final offset to the valid range of character indices
    return position.offset.clamp(0, textLength);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure painter reflects current state, especially if updated externally
    if (_lyricTextPainter.text?.toPlainText() != widget.lyricLine.text) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _updateTextPainter();
          });
        }
      });
    }

    // Calculate the required width for the ChordEditor's content area
    // Based on the measured text width + padding on both sides
    final double requiredEditorWidth =
        _lyricTextPainter.width + _textFieldHorizontalPadding * 2 + 20.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.blue.shade50,
      ),
      child: Column(
        // Keep the outer Column for structure
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row with split button
          Row(
            children: [
              const Icon(Icons.music_note, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Chord/Lyric Pair',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.call_split, size: 16),
                tooltip: 'Split into separate lines',
                onPressed: () {
                  widget.onSplitPair(
                      widget.sectionIndex, widget.chordLineIndex);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Wrap the editable content in a SingleChildScrollView
          SingleChildScrollView(
            controller: _scrollController, // Assign the controller
            scrollDirection: Axis.horizontal,
            child: Column(
              // Inner Column for ChordEditor and TextField
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChordEditor(
                  chordText: widget.chordLine.text,
                  onTextChanged: _updateChordText,
                  accentColor: Colors.blue,
                  fontSize: 14,
                  songKey: widget.songKey,
                  getXFromPosition: _getLyricXFromPosition,
                  getPositionFromX: _getLyricPositionFromX,
                  lyricsLength: widget.lyricLine.text.length,
                  requiredWidth: requiredEditorWidth,
                  editorHeight: 35,
                ),
                const SizedBox(height: 4),
                // Constrain the TextField's width to match the ChordEditor's required width
                SizedBox(
                  width: requiredEditorWidth,
                  child: TextField(
                    controller: _lyricController,
                    onChanged: _updateLyrics,
                    style: _lyricStyle,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: _textFieldHorizontalPadding, vertical: 8),
                      hintText: 'Enter lyrics',
                      isDense: true,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ), // End SingleChildScrollView

          // Actions Row (outside the scroll view)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: () => widget.onMoveLine(
                    widget.sectionIndex, widget.chordLineIndex - 1),
                tooltip: 'Move up',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                onPressed: () => widget.onMoveLine(
                    widget.sectionIndex, widget.chordLineIndex),
                tooltip: 'Move down',
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  widget.onRemoveLine(
                      widget.sectionIndex, widget.chordLineIndex);
                  widget.onRemoveLine(
                      widget.sectionIndex, widget.chordLineIndex);
                },
                tooltip: 'Remove pair',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
