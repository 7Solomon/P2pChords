import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';

enum SectionDuplicateAction {
  keepFirst,
  keepSecond,
  keepBoth,
  cancel,
}

class SectionDuplicateDialog extends StatefulWidget {
  final PreliminarySection firstSection;
  final PreliminarySection secondSection;
  final String sectionTitle;

  const SectionDuplicateDialog({
    super.key,
    required this.firstSection,
    required this.secondSection,
    required this.sectionTitle,
  });

  @override
  State<SectionDuplicateDialog> createState() => _SectionDuplicateDialogState();
}

class _SectionDuplicateDialogState extends State<SectionDuplicateDialog> {
  SectionDuplicateAction? selectedAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doppelter Abschnitt gefunden',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"${widget.sectionTitle}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Zwei verschiedene Versionen dieses Abschnitts wurden gefunden. Wählen Sie, wie damit umgegangen werden soll:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Difference summary
              _buildDifferenceSummary(),

              const SizedBox(height: 16),

              // Section comparison
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First section
                      Expanded(
                        child: _buildSectionPreview(
                          'Erste Version',
                          widget.firstSection,
                          true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Second section
                      Expanded(
                        child: _buildSectionPreview(
                          'Zweite Version',
                          widget.secondSection,
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Column(
                children: [
                  _buildActionButton(
                    'Nur erste Version behalten',
                    SectionDuplicateAction.keepFirst,
                    Icons.looks_one,
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Nur zweite Version behalten',
                    SectionDuplicateAction.keepSecond,
                    Icons.looks_two,
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Beide behalten (nummeriert)',
                    SectionDuplicateAction.keepBoth,
                    Icons.content_copy,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SectionDuplicateAction.cancel),
          child: Text(
            'Abbrechen',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: selectedAction != null
              ? () => Navigator.of(context).pop(selectedAction)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Anwenden',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifferenceSummary() {
    final theme = Theme.of(context);
    final differences = _analyzeDifferences();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Unterschiede:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...differences.map((diff) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Text(
                  '• $diff',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  List<String> _analyzeDifferences() {
    final first = widget.firstSection;
    final second = widget.secondSection;
    final differences = <String>[];

    // Line count difference
    if (first.lines.length != second.lines.length) {
      differences.add(
          'Erste Version: ${first.lines.length} Zeilen, Zweite Version: ${second.lines.length} Zeilen');
    }

    // Chord line differences
    final firstChordLines = first.lines.where((l) => l.isChordLine).length;
    final secondChordLines = second.lines.where((l) => l.isChordLine).length;
    if (firstChordLines != secondChordLines) {
      differences.add(
          'Akkordzeilen - Erste: $firstChordLines, Zweite: $secondChordLines');
    }

    // Content differences
    int differentLines = 0;
    final maxLines = [first.lines.length, second.lines.length]
        .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLines; i++) {
      final firstLine = i < first.lines.length ? first.lines[i] : null;
      final secondLine = i < second.lines.length ? second.lines[i] : null;

      if (firstLine == null ||
          secondLine == null ||
          firstLine.text != secondLine.text ||
          firstLine.isChordLine != secondLine.isChordLine) {
        differentLines++;
      }
    }

    if (differentLines > 0) {
      differences.add('$differentLines Zeilen unterscheiden sich');
    }

    if (differences.isEmpty) {
      differences.add('Strukturelle Unterschiede erkannt');
    }

    return differences;
  }

  Widget _buildActionButton(
    String text,
    SectionDuplicateAction action,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedAction == action;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAction = action;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? color : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPreview(
    String title,
    PreliminarySection section,
    bool isFirst,
  ) {
    final theme = Theme.of(context);
    final otherSection = isFirst ? widget.secondSection : widget.firstSection;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFirst ? Colors.blue[50] : Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isFirst ? Colors.blue[700] : Colors.green[700],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: section.lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                final diff = _getLineDifference(line, index, otherSection);

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: diff.isDifferent
                      ? const EdgeInsets.all(4)
                      : EdgeInsets.zero,
                  decoration: diff.isDifferent
                      ? BoxDecoration(
                          color: diff.backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: diff.borderColor, width: 1),
                        )
                      : null,
                  child: Row(
                    children: [
                      if (diff.isDifferent)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: Icon(
                            diff.icon,
                            size: 12,
                            color: diff.iconColor,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          line.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: line.isChordLine ? 'monospace' : null,
                            fontWeight: line.isChordLine
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: diff.isDifferent
                                ? diff.textColor
                                : line.isChordLine
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  LineDifference _getLineDifference(
      PreliminaryLine line, int index, PreliminarySection otherSection) {
    // Line doesn't exist in other section
    if (index >= otherSection.lines.length) {
      return LineDifference(
        isDifferent: true,
        backgroundColor: Colors.blue[50]!,
        borderColor: Colors.blue[200]!,
        textColor: Colors.blue[800]!,
        icon: Icons.add,
        iconColor: Colors.blue[600]!,
      );
    }

    final otherLine = otherSection.lines[index];

    // Lines are identical
    if (line.text == otherLine.text &&
        line.isChordLine == otherLine.isChordLine) {
      return LineDifference(isDifferent: false);
    }

    // Lines are different
    return LineDifference(
      isDifferent: true,
      backgroundColor: Colors.orange[50]!,
      borderColor: Colors.orange[200]!,
      textColor: Colors.orange[800]!,
      icon: Icons.edit,
      iconColor: Colors.orange[600]!,
    );
  }
}

class LineDifference {
  final bool isDifferent;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;

  LineDifference({
    required this.isDifferent,
    this.backgroundColor = Colors.transparent,
    this.borderColor = Colors.transparent,
    this.textColor = Colors.black,
    this.icon = Icons.info,
    this.iconColor = Colors.grey,
  });
}

/// Shows the section duplicate dialog and returns the user's choice
Future<SectionDuplicateAction?> showSectionDuplicateDialog({
  required BuildContext context,
  required PreliminarySection firstSection,
  required PreliminarySection secondSection,
  required String sectionTitle,
}) async {
  return await showDialog<SectionDuplicateAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SectionDuplicateDialog(
      firstSection: firstSection,
      secondSection: secondSection,
      sectionTitle: sectionTitle,
    ),
  );
}
