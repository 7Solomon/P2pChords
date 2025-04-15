import 'dart:math';
import 'dart:ui';

import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/components/chord_editor.dart';

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
  final Function(int, int) onSplitPair; // Add this new callback

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
    required this.onSplitPair, // Add this parameter
  });

  @override
  State<ChordLyricPair> createState() => _ChordLyricPairState();
}

class _ChordLyricPairState extends State<ChordLyricPair> {
  late TextEditingController _lyricController;

  @override
  void initState() {
    super.initState();
    _lyricController = TextEditingController(text: widget.lyricLine.text);
  }

  @override
  void dispose() {
    _lyricController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChordLyricPair oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyricLine.text != widget.lyricLine.text) {
      _lyricController.text = widget.lyricLine.text;
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.blue.shade50,
      ),
      child: Column(
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

              // Add split button
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

          // Chord editor and lyrics field
          ChordEditor(
            text: widget.chordLine.text,
            onTextChanged: _updateChordText,
            accentColor: Colors.blue,
            // Don't show text field since we need to align chords with lyrics
            showTextField: false,
          ),

          // Lyrics field
          TextField(
            controller: _lyricController,
            onChanged: _updateLyrics,
            style: const TextStyle(fontSize: 16, height: 1.0),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Enter lyrics',
            ),
          ),

          // Help text
          // Dont like is verbose
          //Padding(
          //  padding: const EdgeInsets.only(top: 8),
          //  child: Text(
          //    '• Tap to add chord, drag to reposition, tap to edit, long press to delete',
          //    style: TextStyle(
          //      fontSize: 12,
          //      color: Colors.grey.shade700,
          //      fontStyle: FontStyle.italic,
          //    ),
          //  ),
          //),

          // Actions
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
                  // Remove both lines
                  widget.onRemoveLine(
                      widget.sectionIndex, widget.chordLineIndex);
                  widget.onRemoveLine(
                      widget.sectionIndex, widget.lyricLineIndex - 1);
                  // -1 because after first deletion, indices shift
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
