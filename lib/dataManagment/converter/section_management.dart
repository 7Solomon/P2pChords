import 'package:P2pChords/dataManagment/Pages/edit/style.dart';
import 'package:P2pChords/dataManagment/converter/classes.dart';
import 'package:flutter/material.dart';

/// Normalize section content for comparison (ignore spacing, case differences)
String _normalizeSectionContent(PreliminarySection section) {
  return section.lines
      .map((line) => line.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
      .where((text) => text.isNotEmpty)
      .join('|');
}

List<PreliminaryLine> _copyLines(List<PreliminaryLine> lines) {
  return lines
      .map((l) => PreliminaryLine(
          text: l.text, isChordLine: l.isChordLine, wasSplit: l.wasSplit))
      .toList();
}


/// Group sections by title and detect duplicates
List<SectionGroup> groupSections(List<PreliminarySection> sections) {
  final Map<String, List<SectionOccurrence>> grouped = {};

  for (int i = 0; i < sections.length; i++) {
    final section = sections[i];
    final title = section.title;
    final normalized = _normalizeSectionContent(section);

    grouped.putIfAbsent(title, () => []);
    grouped[title]!.add(SectionOccurrence(
      originalIndex: i,
      section: section,
      normalizedContent: normalized,
    ));
  }

  return grouped.entries.map((entry) {
    final group = SectionGroup(
      title: entry.key,
      occurrences: entry.value,
    );

    // Auto-resolve if all content is identical
    if (group.hasIdenticalContent && group.hasDuplicates) {
      group.resolution = DuplicateResolution.mergeIdentical;
    }

    return group;
  }).toList();
}

List<PreliminarySection> applyResolutions(List<SectionGroup> groups) {
  final result = <PreliminarySection>[];

  // Sort groups by first occurrence index to preserve order
  final sortedGroups = groups.toList()
    ..sort((a, b) => a.occurrences.first.originalIndex
        .compareTo(b.occurrences.first.originalIndex));

  for (final group in sortedGroups) {
    switch (group.resolution) {
      case DuplicateResolution.mergeIdentical:
        // Keep only first occurrence, no numbering
        result.add(group.occurrences.first.section);
        break;

      case DuplicateResolution.keepFirst:
        result.add(group.occurrences.first.section);
        break;

      case DuplicateResolution.keepSpecific:
        // Keep the specific version chosen by user
        final index = group.specificVersionIndex ?? 0;
        if (index >= 0 && index < group.occurrences.length) {
          result.add(group.occurrences[index].section);
        } else {
          result.add(group.occurrences.first.section); // Fallback
        }
        break;

      case DuplicateResolution.keepAll:
        if (group.occurrences.length == 1) {
          result.add(group.occurrences.first.section);
        } else {
          // Add numbered versions
          for (int i = 0; i < group.occurrences.length; i++) {
            final occurrence = group.occurrences[i];
            final numberedSection = PreliminarySection(
              title: '${group.title} (${i + 1})',
              lines: _copyLines(occurrence.section.lines),
            );
            result.add(numberedSection);
          }
        }
        break;
    }
  }

  return result;
}

/// Show compact mobile-friendly duplicate resolution dialog
Future<List<SectionGroup>?> showDuplicateResolutionDialog({
  required BuildContext context,
  required List<SectionGroup> groups,
}) async {
  return await showDialog<List<SectionGroup>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DuplicateResolutionDialog(groups: groups),
  );
}


class _DuplicateResolutionDialog extends StatefulWidget {
  final List<SectionGroup> groups;

  const _DuplicateResolutionDialog({required this.groups});

  @override
  State<_DuplicateResolutionDialog> createState() =>
      _DuplicateResolutionDialogState();
}

class _DuplicateResolutionDialogState
    extends State<_DuplicateResolutionDialog> {
  late List<SectionGroup> workingGroups;

  @override
  void initState() {
    super.initState();
    // Create working copy
    workingGroups = widget.groups.map((g) => SectionGroup(
      title: g.title,
      occurrences: g.occurrences,
      resolution: g.resolution,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: UIStyle.primary,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Duplicate Sections Found',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () => _showHelp(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: workingGroups.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  return _SectionGroupCard(
                    group: workingGroups[index],
                    onResolutionChanged: (resolution) {
                      setState(() {
                        workingGroups[index].resolution = resolution;
                      });
                    },
                  );
                },
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: UIStyle.button,
                    onPressed: () => Navigator.pop(context, workingGroups),
                    child: const Text('Übernehmen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Resolve Duplicates'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Alle behalten: Nummeriert alle Versionen (Verse (1), Verse (2))'),
              SizedBox(height: 8),
              Text('• Nur Erste Behalten: Verwendet nur die erste Vorkommeng und verwirft die anderen'),
              SizedBox(height: 8),
              Text('• Unterschiedlicher Inhalt wird gelb hervorgehoben'),
              SizedBox(height: 8),
              Text('• Tippe auf eine Version, um ihren vollständigen Inhalt anzuzeigen'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SectionGroupCard extends StatelessWidget {
  final SectionGroup group;
  final ValueChanged<DuplicateResolution> onResolutionChanged;

  const _SectionGroupCard({
    required this.group,
    required this.onResolutionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.library_music, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${group.occurrences.length} Versionen',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Show content difference indicator
            if (!group.hasIdenticalContent) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange[800]),
                    const SizedBox(width: 4),
                    Text(
                      'Versionen haben unterschiedliche Inhalte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Preview of differences
            ...group.occurrences.asMap().entries.map((entry) {
              final index = entry.key;
              final occurrence = entry.value;
              final isSelected = (group.resolution == DuplicateResolution.keepFirst && index == 0) ||
                                (group.resolution == DuplicateResolution.keepSpecific && 
                                 index == (group.specificVersionIndex ?? 0));
              
              return _OccurrencePreview(
                occurrence: occurrence,
                index: index + 1,
                isSelected: isSelected,
                compareWith: index > 0 ? group.occurrences[0] : null,
              );
            }),

            const SizedBox(height: 12),

            // Resolution options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Alle Behalten (Nummeriert)'),
                  selected: group.resolution == DuplicateResolution.keepAll,
                  onSelected: (_) => onResolutionChanged(DuplicateResolution.keepAll),
                ),
                ChoiceChip(
                  label: const Text('Nur Erste Behalten'),
                  selected: group.resolution == DuplicateResolution.keepFirst,
                  onSelected: (_) => onResolutionChanged(DuplicateResolution.keepFirst),
                ),
                ChoiceChip(
                  label: const Text('Spezifische Version'),
                  selected: group.resolution == DuplicateResolution.keepSpecific,
                  onSelected: (_) => onResolutionChanged(DuplicateResolution.keepSpecific),
                ),
              ],
            ),

            // Show version dropdown when keepSpecific is selected
            if (group.resolution == DuplicateResolution.keepSpecific) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Version Auswählen:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                        value: group.specificVersionIndex ?? 0,
                        isExpanded: true,
                        items: List.generate(
                          group.occurrences.length,
                          (index) => DropdownMenuItem(
                            value: index,
                            child: Text('Version ${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            group.specificVersionIndex = value;
                            onResolutionChanged(DuplicateResolution.keepSpecific);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OccurrencePreview extends StatelessWidget {
  final SectionOccurrence occurrence;
  final int index;
  final bool isSelected;
  final SectionOccurrence? compareWith; // For diff calculation

  const _OccurrencePreview({
    required this.occurrence,
    required this.index,
    this.isSelected = false,
    this.compareWith,
  });

  // Calculate a smart preview that shows what's different
  String _getSmartPreview() {
    final lines = occurrence.section.lines
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (compareWith == null || lines.isEmpty) {
      // No comparison, just show first few lines
      return lines.take(2).join(' • ');
    }

    // Find lines that are different from the comparison
    final compareLines = compareWith!.section.lines
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final differentLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      if (i >= compareLines.length || lines[i] != compareLines[i]) {
        differentLines.add(lines[i]);
        if (differentLines.length >= 2) break;
      }
    }

    if (differentLines.isEmpty) {
      return lines.take(2).join(' • ');
    }

    return '≠ ${differentLines.join(' • ')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDifferences = compareWith != null && 
                          occurrence.normalizedContent != compareWith!.normalizedContent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.green[50]
            : hasDifferences 
                ? Colors.yellow[50]
                : Colors.grey[50],
        border: Border.all(
          color: isSelected 
              ? Colors.green 
              : hasDifferences
                  ? Colors.orange[300]!
                  : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.green 
                  : hasDifferences 
                      ? Colors.orange[400]
                      : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSmartPreview(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontStyle: hasDifferences ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (hasDifferences) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.difference, size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Unterschiede gefunden',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 18),
            onPressed: () => _showDetailedDiff(context),
            tooltip: 'Detaillierte Ansicht',
          ),
        ],
      ),
    );
  }

  void _showDetailedDiff(BuildContext context) {
    final thisLines = occurrence.section.lines;
    final compareLines = compareWith?.section.lines ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: Row(
                  children: [
                    Text(
                      'Version $index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (compareWith != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'vs Version 1',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Content with diff highlighting
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: thisLines.length,
                  itemBuilder: (context, lineIndex) {
                    final line = thisLines[lineIndex];
                    final isChordLine = line.isChordLine;
                    
                    // Calculate diff
                    String? diffType;
                    if (compareWith != null) {
                      if (lineIndex >= compareLines.length) {
                        diffType = 'added';
                      } else if (line.text.trim() != compareLines[lineIndex].text.trim()) {
                        diffType = 'changed';
                      }
                    }

                    Color? backgroundColor;
                    Color? textColor;
                    
                    if (diffType == 'added') {
                      backgroundColor = Colors.green[100];
                      textColor = Colors.green[900];
                    } else if (diffType == 'changed') {
                      backgroundColor = Colors.orange[100];
                      textColor = Colors.orange[900];
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: diffType != null 
                            ? Border.all(
                                color: diffType == 'added' 
                                    ? Colors.green 
                                    : Colors.orange,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (diffType != null) ...[
                            Icon(
                              diffType == 'added' ? Icons.add_circle : Icons.edit,
                              size: 14,
                              color: textColor,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              line.text.isEmpty ? '(leere Zeile)' : line.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: textColor ?? (isChordLine ? Colors.blue : Colors.black87),
                                fontWeight: isChordLine ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Footer with legend
              if (compareWith != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: Colors.green,
                        icon: Icons.add_circle,
                        label: 'Hinzugefügt',
                      ),
                       SizedBox(width: 16),
                      _LegendItem(
                        color: Colors.orange,
                        icon: Icons.edit,
                        label: 'Geändert',
                      ),
                    ],
                  ),
                ),
              ],

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: UIStyle.button,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Schließen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }
}