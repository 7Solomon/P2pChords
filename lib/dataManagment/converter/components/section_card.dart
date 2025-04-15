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
  final Function(int, int) onMoveLine;
  final Function(int, int) onSplitChordLyricPair;

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
            _buildLineGroups(),

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

    for (int i = 0; i < lines.length; i++) {
      final isChordLine = lines[i].isChordLine;
      final bool isPaired = i < lines.length - 1 &&
          lines[i].isChordLine &&
          !lines[i + 1].isChordLine &&
          !lines[i].wasSplit && // Check that it wasn't split
          !lines[i + 1].wasSplit; // Check that it wasn't split

      if (isPaired) {
        // Create a chord-lyric pair with the split callback
        lineWidgets.add(ChordLyricPair(
          chordLine: lines[i],
          lyricLine: lines[i + 1],
          chordLineIndex: i,
          lyricLineIndex: i + 1,
          sectionIndex: sectionIndex,
          onUpdateLineText: onUpdateLineText,
          onRemoveLine: onRemoveLine,
          onMoveLine: onMoveLine,
          onSplitPair: onSplitChordLyricPair, // Pass the callback
        ));
        i++; // Skip the next line as we've already included it
      } else {
        // Create a single line
        lineWidgets.add(LineItem(
          line: lines[i],
          sectionIndex: sectionIndex,
          lineIndex: i,
          onUpdateLineText: onUpdateLineText,
          onToggleLineType: onToggleLineType,
          onRemoveLine: onRemoveLine,
          onMoveLine: onMoveLine,
        ));
      }
    }

    return Column(
      children: lineWidgets,
    );
  }
}
