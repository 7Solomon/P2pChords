import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

/// Reusable components for the conversion review page

class SectionCard extends StatelessWidget {
  final SongSection section;
  final int sectionIndex;
  final Function(int, String) onSectionTitleChanged;
  final Function(int, int, LineType) onLineTypeChanged;
  final Function(int, int, int?) onChordLineAssociationChanged;
  final Function(int, int, String) onLyricsChanged;
  final Function(int, int, int, String) onChordChanged;

  const SectionCard({
    Key? key,
    required this.section,
    required this.sectionIndex,
    required this.onSectionTitleChanged,
    required this.onLineTypeChanged,
    required this.onChordLineAssociationChanged,
    required this.onLyricsChanged,
    required this.onChordChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title (editable)
            EditableSectionTitle(
              title: section.title,
              onChanged: (newTitle) =>
                  onSectionTitleChanged(sectionIndex, newTitle),
            ),
            const Divider(),

            // Lines with lyrics and chords
            for (int lineIndex = 0;
                lineIndex < section.lines.length;
                lineIndex++)
              LineItem(
                line: section.lines[lineIndex],
                sectionIndex: sectionIndex,
                lineIndex: lineIndex,
                onLineTypeChanged: onLineTypeChanged,
                onChordLineAssociationChanged: onChordLineAssociationChanged,
                onLyricsChanged: onLyricsChanged,
                onChordChanged: onChordChanged,
                allLines: section.lines,
              ),
          ],
        ),
      ),
    );
  }
}

class EditableSectionTitle extends StatelessWidget {
  final String title;
  final Function(String) onChanged;

  const EditableSectionTitle({
    Key? key,
    required this.title,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Section: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: InkWell(
            onTap: () => _showEditDialog(
                context, 'Edit Section Title', title, onChanged),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () =>
              _showEditDialog(context, 'Edit Section Title', title, onChanged),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue,
      Function(String) onSave) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

enum LineType { lyric, chord }

class LineItem extends StatelessWidget {
  final LyricLine line;
  final int sectionIndex;
  final int lineIndex;
  final List<LyricLine> allLines;
  final Function(int, int, LineType) onLineTypeChanged;
  final Function(int, int, int?) onChordLineAssociationChanged;
  final Function(int, int, String) onLyricsChanged;
  final Function(int, int, int, String) onChordChanged;

  const LineItem({
    Key? key,
    required this.line,
    required this.sectionIndex,
    required this.lineIndex,
    required this.onLineTypeChanged,
    required this.onChordLineAssociationChanged,
    required this.onLyricsChanged,
    required this.onChordChanged,
    required this.allLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isChordLine = line.chords.isNotEmpty;
    final LineType currentType = isChordLine ? LineType.chord : LineType.lyric;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line type selector
          Row(
            children: [
              DropdownButton<LineType>(
                value: currentType,
                items: const [
                  DropdownMenuItem(
                    value: LineType.lyric,
                    child: Text('Lyrics'),
                  ),
                  DropdownMenuItem(
                    value: LineType.chord,
                    child: Text('Chords'),
                  ),
                ],
                onChanged: (newType) {
                  if (newType != null && newType != currentType) {
                    onLineTypeChanged(sectionIndex, lineIndex, newType);
                  }
                },
              ),

              const SizedBox(width: 16),

              // For chord lines, show association dropdown
              if (currentType == LineType.chord)
                Expanded(
                  child: Row(
                    children: [
                      const Text('Associated with: '),
                      Expanded(
                        child: _buildLyricLineAssociationDropdown(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Display content based on line type
          if (currentType == LineType.chord)
            _buildChordLineContent(context)
          else
            _buildLyricLineContent(context),

          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildLyricLineAssociationDropdown(BuildContext context) {
    // Find lyric lines to associate with
    List<DropdownMenuItem<int?>> items = [];

    // Add "None" option
    items.add(const DropdownMenuItem(
      value: null,
      child: Text('None'),
    ));

    // Add all lyric lines
    for (int i = 0; i < allLines.length; i++) {
      if (i != lineIndex && allLines[i].chords.isEmpty) {
        items.add(DropdownMenuItem(
          value: i,
          child: Text(
              'Line ${i + 1}: ${allLines[i].lyrics.substring(0, allLines[i].lyrics.length > 20 ? 20 : allLines[i].lyrics.length)}...'),
        ));
      }
    }

    // Determine the current association (placeholder logic)
    int? currentAssociation;
    // In a real implementation, you'd store this association in your data model

    return DropdownButton<int?>(
      items: items,
      value: currentAssociation,
      hint: const Text('Select lyric line'),
      isExpanded: true,
      onChanged: (value) {
        onChordLineAssociationChanged(sectionIndex, lineIndex, value);
      },
    );
  }

  Widget _buildChordLineContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chords:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8.0,
          children: [
            for (int chordIndex = 0;
                chordIndex < line.chords.length;
                chordIndex++)
              Chip(
                label: Text(line.chords[chordIndex].value),
                deleteIcon: const Icon(Icons.edit, size: 16),
                onDeleted: () {
                  _showEditChordDialog(
                    context,
                    'Edit Chord',
                    line.chords[chordIndex].value,
                    (newValue) => onChordChanged(
                        sectionIndex, lineIndex, chordIndex, newValue),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLyricLineContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lyrics:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showEditDialog(
                  context,
                  'Edit Lyrics',
                  line.lyrics,
                  (newValue) =>
                      onLyricsChanged(sectionIndex, lineIndex, newValue),
                ),
                child: Text(line.lyrics),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () => _showEditDialog(
                context,
                'Edit Lyrics',
                line.lyrics,
                (newValue) =>
                    onLyricsChanged(sectionIndex, lineIndex, newValue),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue,
      Function(String) onSave) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditChordDialog(BuildContext context, String title,
      String initialValue, Function(String) onSave) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Utility functions for showing dialog boxes
void showEditDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  required Function(String) onSave,
}) {
  final TextEditingController controller =
      TextEditingController(text: initialValue);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        maxLines: null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onSave(controller.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
