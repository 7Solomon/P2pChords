import 'package:P2pChords/dataManagment/converter/components/chord_lyric_pair.dart';
import 'package:P2pChords/dataManagment/converter/components/line_item.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
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
  // --- ADDED: Callback for combining lines ---
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
    // --- ADDED: Required parameter ---
    required this.onCombineLines,
    required this.songKey,
  });

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
            // Section title with edit capability
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: section.title),
                    onChanged: (value) =>
                        onUpdateSectionTitle(sectionIndex, value),
                    decoration: const InputDecoration(
                      labelText: 'Section Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onRemoveSection(sectionIndex),
                  tooltip: 'Delete section',
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),

            // Lines in this section, grouped by pairs
            _buildLineGroups(), // This method needs adjustment

            // Add line button
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Line'),
              onPressed: () => onAddLine(sectionIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineGroups() {
    final lines = section.lines;
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
          key: ValueKey('pair_${sectionIndex}_$i'), // Add key
          chordLine: currentLine,
          lyricLine: lines[i + 1],
          chordLineIndex: i,
          lyricLineIndex: i + 1,
          sectionIndex: sectionIndex,
          onUpdateLineText: onUpdateLineText,
          onRemoveLine:
              onRemoveLine, // Removing a pair might need special handling
          onMoveLine: onMoveLine, // Moving a pair might need special handling
          onSplitPair: onSplitChordLyricPair,
          songKey: songKey,
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
          key: ValueKey('line_${sectionIndex}_$i'), // Add key
          line: currentLine,
          sectionIndex: sectionIndex,
          lineIndex: i,
          onUpdateLineText: onUpdateLineText,
          onToggleLineType: onToggleLineType,
          onRemoveLine: onRemoveLine,
          onMoveLine: onMoveLine,

          onCombineLines:
              canCombine ? onCombineLines : null, // Pass only if combinable
        ));
        i++; // Increment by 1
      }
    }

    return Column(
      children: lineWidgets,
    );
  }
}
