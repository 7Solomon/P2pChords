import 'dart:math';

import 'package:P2pChords/dataManagment/converter/components/chord_editor.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a single line (chord or lyric)
class LineItem extends StatefulWidget {
  final PreliminaryLine line;
  final int sectionIndex;
  final int lineIndex;
  final Function(int, int, String) onUpdateLineText;
  final Function(int, int) onToggleLineType;
  final Function(int, int) onRemoveLine;
  final Function(int, int) onMoveLine;

  const LineItem({
    super.key,
    required this.line,
    required this.sectionIndex,
    required this.lineIndex,
    required this.onUpdateLineText,
    required this.onToggleLineType,
    required this.onRemoveLine,
    required this.onMoveLine,
  });

  @override
  State<LineItem> createState() => _LineItemState();
}

class _LineItemState extends State<LineItem> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.line.text);
  }

  @override
  void didUpdateWidget(LineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.text != widget.line.text) {
      _textController.text = widget.line.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateLineText(String newText) {
    widget.onUpdateLineText(widget.sectionIndex, widget.lineIndex, newText);
  }

  @override
  Widget build(BuildContext context) {
    final isChordLine = widget.line.isChordLine;
    final accentColor = isChordLine ? Colors.amber : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor.shade200),
        borderRadius: BorderRadius.circular(8.0),
        color: accentColor.shade50,
      ),
      child: Column(
        children: [
          // Header with type toggle and actions
          Row(
            children: [
              // Chord/lyric toggle switch
              Switch(
                value: isChordLine,
                onChanged: (value) => widget.onToggleLineType(
                    widget.sectionIndex, widget.lineIndex),
                activeColor: Colors.amber.shade800,
                inactiveThumbColor: Colors.green.shade800,
                activeTrackColor: Colors.amber.shade200,
                inactiveTrackColor: Colors.green.shade200,
              ),
              Text(
                isChordLine ? 'Chord Line' : 'Lyric Line',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isChordLine
                      ? Colors.amber.shade800
                      : Colors.green.shade800,
                ),
              ),

              const Spacer(),

              // Move and delete actions
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: widget.lineIndex > 0
                    ? () => widget.onMoveLine(
                        widget.sectionIndex, widget.lineIndex - 1)
                    : null,
                tooltip: 'Move up',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                onPressed: () =>
                    widget.onMoveLine(widget.sectionIndex, widget.lineIndex),
                tooltip: 'Move down',
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () =>
                    widget.onRemoveLine(widget.sectionIndex, widget.lineIndex),
                tooltip: 'Remove line',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Content: chord editor or lyric text field
          isChordLine
              ? ChordEditor(
                  text: widget.line.text,
                  onTextChanged: _updateLineText,
                  accentColor: accentColor,
                )
              : TextField(
                  controller: _textController,
                  onChanged: _updateLineText,
                  decoration: const InputDecoration(
                    hintText: 'Enter lyrics',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

          // Help text for chord lines
          // is unecessary looks verbose
          //if (isChordLine)
          //  Padding(
          //    padding: const EdgeInsets.only(top: 8),
          //    child: Text(
          //      '• Tap to add chord, drag to reposition, tap to edit, long press to delete',
          //      style: TextStyle(
          //        fontSize: 12,
          //        color: Colors.grey.shade700,
          //        fontStyle: FontStyle.italic,
          //      ),
          //    ),
          //  ),
        ],
      ),
    );
  }
}
