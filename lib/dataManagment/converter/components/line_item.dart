import 'dart:math';

import 'package:P2pChords/dataManagment/converter/components/chord_editor.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/classes.dart';


class LineItem extends StatefulWidget {
  final PreliminaryLine line;
  final int sectionIndex;
  final int lineIndex;
  final Function(int, int, String) onUpdateLineText;
  final Function(int, int) onToggleLineType;
  final Function(int, int) onRemoveLine;
  final Function(int, int) onMoveLine;
  final Function(int, int) onCleanLine;
  final Function(int, int)? onCombineLines;

  const LineItem({
    super.key,
    required this.line,
    required this.sectionIndex,
    required this.lineIndex,
    required this.onUpdateLineText,
    required this.onToggleLineType,
    required this.onRemoveLine,
    required this.onMoveLine,
    required this.onCleanLine,
    this.onCombineLines,
  });

  @override
  State<LineItem> createState() => _LineItemState();
}

class _LineItemState extends State<LineItem> {
  // Keep controller for lyric TextField
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.line.text);
  }

  @override
  void didUpdateWidget(LineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update lyric controller only if it's not a chord line
    if (!widget.line.isChordLine && oldWidget.line.text != widget.line.text) {
      // Use WidgetsBinding to schedule update after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _textController.text != widget.line.text) {
          _textController.text = widget.line.text;
          // Optionally move cursor to end
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
      });
    }
    // If switching from lyric to chord, ensure controller has latest text
    // (ChordEditor will take over displaying/editing)
    else if (widget.line.isChordLine && !oldWidget.line.isChordLine) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _textController.text != widget.line.text) {
          _textController.text = widget.line.text;
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Keep helper for consistency
  void _updateLineText(String newText) {
    widget.onUpdateLineText(widget.sectionIndex, widget.lineIndex, newText);
  }

  @override
  Widget build(BuildContext context) {
    final isChordLine = widget.line.isChordLine;
    final isAmbiguousChordLine = widget.line.chordLineCertainty < 0.33;
    // Use orange for chords, green for lyrics
    final Color borderColor =
        isChordLine ? Colors.amber.shade200 : Colors.green.shade200;
    final Color backgroundColor =
        isChordLine ? Colors.amber.shade50 : Colors.green.shade50;
    final Color accentColor = isChordLine
        ? Colors.amber.shade800
        : Colors.green.shade800; // For text/icons

    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 4.0), // Use symmetric vertical margin
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        // Use dynamic colors based on line type
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8.0),
        color: backgroundColor,
      ),
      child: Row(
        // Use Row for main layout
        children: [
          Expanded(
            child: Column(
              // Use Column for content (editor/textfield)
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Switch(
                  value: isChordLine,
                  onChanged: (value) => widget.onToggleLineType(
                      widget.sectionIndex, widget.lineIndex),
                  activeColor: Colors.amber.shade800, // Chord color
                  inactiveThumbColor: Colors.green.shade800, // Lyric color
                  activeTrackColor: Colors.amber.shade200,
                  inactiveTrackColor: Colors.green.shade200,
                ),
                Text(
                  isChordLine ? 'Chord Line' : 'Lyric Line',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor, // Use dynamic accent color
                  ),
                ),
                isChordLine
                    ? SingleChildScrollView(
                        // Keep ScrollView for ChordEditor
                        scrollDirection: Axis.horizontal,
                        child: ChordEditor(
                          // Pass necessary props for standalone ChordEditor
                          chordText: widget.line.text,
                          onTextChanged: _updateLineText,
                          accentColor: accentColor, // Pass dynamic accent color
                          fontSize: 16, // Example font size
                          editorHeight: 40, // Example height
                          // Let ChordEditor handle its internal logic
                        ),
                      )
                    : TextField(
                        controller: _textController,
                        onChanged: _updateLineText, // Use helper
                        decoration: const InputDecoration(
                          hintText: 'Enter lyrics',
                          // Restore simpler border for TextField
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style:
                            TextStyle(color: accentColor), // Style lyric text
                      ),
              ],
            ),
          ),
          // Action Buttons Column
          Column(
              mainAxisSize: MainAxisSize.min, // Take minimum space
              children: [
                // Combine Button (Conditional)
                if (widget.onCombineLines != null)
                  IconButton(
                    icon: const Icon(Icons.merge_type,
                        color: Colors
                            .blue), // Keep blue for merge? Or use a neutral color?
                    tooltip: 'Combine with next line',
                    onPressed: () => widget.onCombineLines!(
                        widget.sectionIndex, widget.lineIndex),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (isAmbiguousChordLine)
                  IconButton(
                    icon: const Icon(Icons.change_circle, color: Colors.black54),
                    tooltip: 'Clean',
                    onPressed: () =>
                        widget.onCleanLine(widget.sectionIndex, widget.lineIndex),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Line',
                  onPressed: () => widget.onRemoveLine(
                      widget.sectionIndex, widget.lineIndex),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ])
        ],
      ),
    );
  }
}
