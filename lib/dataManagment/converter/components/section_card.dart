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
  final Function(int, int) onMoveLine;
  final Function(int) onMoveSectionUp;
  final Function(int) onMoveSectionDown;
  final Function(int, int) onSplitChordLyricPair;
  final Function(int, int) onCombineLines;
  final Function(int, int) onCleanLine;
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
    required this.onMoveSectionUp,
    required this.onMoveSectionDown,
    required this.onSplitChordLyricPair,
    required this.onCombineLines,
    required this.onCleanLine,
    required this.songKey,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late final TextEditingController _titleController;
  bool _isExpanded = true; // State variable for expansion

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section.title != _titleController.text) {
      _titleController.text = widget.section.title;
    }
  }

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
                    controller: _titleController,
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
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => widget.onMoveSectionUp(widget.sectionIndex),
                  tooltip: 'Move section up',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: () =>
                      widget.onMoveSectionDown(widget.sectionIndex),
                  tooltip: 'Move section down',
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
          onCleanLine: widget.onCleanLine,
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
