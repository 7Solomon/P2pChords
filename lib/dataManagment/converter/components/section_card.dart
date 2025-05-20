import 'package:P2pChords/dataManagment/converter/components/chord_lyric_pair.dart';
import 'package:P2pChords/dataManagment/converter/components/line_item.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatefulWidget {
  final PreliminarySection section;
  final int sectionIndex;
  final Function(int, String) onUpdateSectionTitle;
  final Function(int) onRemoveSection;
  final Function(int, int, String) onUpdateLineText;
  final Function(int, int) onToggleLineType;
  final Function(int, int) onRemoveLine;
  final Function(int) onAddLine;
  final Function(int, int)
      onMoveLine; // Assuming direction is handled within callback
  final Function(int, int) onSplitChordLyricPair;
  final Function(int, int) onCombineLines;
  final String songKey;

  const SectionCard({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.onUpdateSectionTitle,
    required this.onRemoveSection,
    required this.onUpdateLineText,
    required this.onToggleLineType,
    required this.onRemoveLine,
    required this.onAddLine,
    required this.onMoveLine,
    required this.onSplitChordLyricPair,
    required this.onCombineLines,
    required this.songKey,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _isExpanded = true; // State variable for expansion

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        TextEditingController(text: widget.section.title),
                    onChanged: (value) =>
                        widget.onUpdateSectionTitle(widget.sectionIndex, value),
                    decoration: const InputDecoration(
                      labelText: 'Section Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: _isExpanded ? 'Collapse section' : 'Expand section',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => widget.onRemoveSection(widget.sectionIndex),
                  tooltip: 'Delete section',
                ),
              ],
            ),
            Visibility(
              visible: _isExpanded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 8),

                  // Lines in this section, grouped by pairs
                  _buildLineGroups(), // This method needs adjustment

                  // Add line button
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Line'),
                    onPressed: () => widget.onAddLine(widget.sectionIndex),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineGroups() {
    final lines = widget.section.lines;
    final List<Widget> lineWidgets = [];
    int i = 0; // Use a while loop for better control over index increment

    while (i < lines.length) {
      final currentLine = lines[i];
      final bool canBePairStart =
          currentLine.isChordLine && !currentLine.wasSplit;
      final bool hasNextLine = i + 1 < lines.length;
      final bool nextLineIsLyric = hasNextLine && !lines[i + 1].isChordLine;
      final bool nextLineIsNotSplit = hasNextLine && !lines[i + 1].wasSplit;

      // Check if it should be rendered as a ChordLyricPair
      if (canBePairStart &&
          hasNextLine &&
          nextLineIsLyric &&
          nextLineIsNotSplit) {
        lineWidgets.add(ChordLyricPair(
          key: ValueKey('pair_${widget.sectionIndex}_$i'), // Add key
          chordLine: currentLine,
          lyricLine: lines[i + 1],
          chordLineIndex: i,
          lyricLineIndex: i + 1,
          sectionIndex: widget.sectionIndex,
          onUpdateLineText: widget.onUpdateLineText,
          onRemoveLine: widget
              .onRemoveLine, // Removing a pair might need special handling
          onMoveLine:
              widget.onMoveLine, // Moving a pair might need special handling
          onSplitPair: widget.onSplitChordLyricPair,
          songKey: widget.songKey,
        ));
        i += 2; // Increment by 2 as we processed a pair
      } else {
        // Render as a single LineItem
        // Check if this line *could* be combined with the next one
        bool canCombine = currentLine.isChordLine &&
            currentLine.wasSplit &&
            hasNextLine &&
            nextLineIsLyric &&
            lines[i + 1].wasSplit;

        lineWidgets.add(LineItem(
          key: ValueKey('line_${widget.sectionIndex}_$i'), // Add key
          line: currentLine,
          sectionIndex: widget.sectionIndex,
          lineIndex: i,
          onUpdateLineText: widget.onUpdateLineText,
          onToggleLineType: widget.onToggleLineType,
          onRemoveLine: widget.onRemoveLine,
          onMoveLine: widget.onMoveLine,

          onCombineLines: canCombine
              ? widget.onCombineLines
              : null, // Pass only if combinable
        ));
        i++; // Increment by 1
      }
    }

    return Column(
      children: lineWidgets,
    );
  }
}
