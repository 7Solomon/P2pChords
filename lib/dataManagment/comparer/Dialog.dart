import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

//comparison dialog for comparing two Song objects
class SongComparisonDialog extends StatefulWidget {
  final String message;
  final Song existingSong;
  final Song newSong;

  const SongComparisonDialog({
    Key? key,
    required this.message,
    required this.existingSong,
    required this.newSong,
  }) : super(key: key);

  @override
  State<SongComparisonDialog> createState() => _SongComparisonDialogState();
}

class _SongComparisonDialogState extends State<SongComparisonDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Header', 'Sections', 'Zusammenfassung'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Song Vergleich',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Tabs to switch between different comparison views
            TabBar(
              controller: _tabController,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              labelColor: Theme.of(context).primaryColor,
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHeaderComparison(),
                  _buildSectionsComparison(),
                  _buildSummaryComparison(),
                ],
              ),
            ),

            // Action buttons
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Überschreiben'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Header comparison (title, key, authors, etc.)
  Widget _buildHeaderComparison() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComparisonRow(
              'Name',
              widget.existingSong.header.name,
              widget.newSong.header.name,
            ),
            _buildComparisonRow(
              'Tonart',
              widget.existingSong.header.key,
              widget.newSong.header.key,
            ),
            _buildComparisonRow(
              'BPM',
              widget.existingSong.header.bpm?.toString() ?? '-',
              widget.newSong.header.bpm?.toString() ?? '-',
            ),
            _buildComparisonRow(
              'Taktart',
              widget.existingSong.header.timeSignature ?? '-',
              widget.newSong.header.timeSignature ?? '-',
            ),
            const SizedBox(height: 16),
            _buildAuthorsComparison(),
          ],
        ),
      ),
    );
  }

  // Compare lists of authors
  Widget _buildAuthorsComparison() {
    final existingAuthors = widget.existingSong.header.authors;
    final newAuthors = widget.newSong.header.authors;
    final maxAuthors = existingAuthors.length > newAuthors.length
        ? existingAuthors.length
        : newAuthors.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Autoren',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('#',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Bestehend',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Neu',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]),

            // Author rows
            for (int i = 0; i < maxAuthors; i++)
              TableRow(
                  decoration: BoxDecoration(
                    color: _getAuthorRowColor(i, existingAuthors, newAuthors),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${i + 1}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(i < existingAuthors.length
                          ? existingAuthors[i]
                          : '-'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(i < newAuthors.length ? newAuthors[i] : '-'),
                    ),
                  ]),
          ],
        ),
      ],
    );
  }

  // Get highlight color for author row
  Color _getAuthorRowColor(
      int index, List<String> existingAuthors, List<String> newAuthors) {
    if (index >= existingAuthors.length) {
      return Colors.green.withOpacity(0.15); // New author added
    }
    if (index >= newAuthors.length) {
      return Colors.red.withOpacity(0.15); // Author removed
    }
    if (existingAuthors[index] != newAuthors[index]) {
      return Colors.amber.withOpacity(0.15); // Author changed
    }
    return Colors.transparent; // No change
  }

  // Build a visual comparison of song sections
  Widget _buildSectionsComparison() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section comparison table header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Bestehende Struktur',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Neue Struktur',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Section comparison
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing sections
              Expanded(
                child: _buildSectionsList(widget.existingSong.sections,
                    isExisting: true),
              ),
              const SizedBox(width: 16),
              // New sections
              Expanded(
                child: _buildSectionsList(widget.newSong.sections,
                    isExisting: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build a list of sections with visual indicators for changes
  Widget _buildSectionsList(List<SongSection> sections,
      {required bool isExisting}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final otherSections =
            isExisting ? widget.newSong.sections : widget.existingSong.sections;
        final matchingSection = _findMatchingSection(section, otherSections);
        final isChanged = matchingSection != null &&
            !_areSectionsEqual(section, matchingSection);
        final isNew = !isExisting &&
            _findMatchingSection(section, widget.existingSong.sections) == null;
        final isRemoved = isExisting &&
            _findMatchingSection(section, widget.newSong.sections) == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _getSectionBorderColor(isChanged, isNew, isRemoved),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSectionHeaderColor(isChanged, isNew, isRemoved),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Status icon
                    _buildStatusIcon(isChanged, isNew, isRemoved),
                  ],
                ),
              ),

              // First few lyrics (preview)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: section.lines.take(3).map((line) {
                    return Text(
                      line.lyrics,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }).toList(),
                ),
              ),

              // Show chord count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${_countChords(section)} Akkorde, ${section.lines.length} Zeilen',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Count chords in a section
  int _countChords(SongSection section) {
    int count = 0;
    for (var line in section.lines) {
      count += line.chords.length;
    }
    return count;
  }

  // Get border color based on section status
  Color _getSectionBorderColor(bool isChanged, bool isNew, bool isRemoved) {
    if (isNew) return Colors.green;
    if (isRemoved) return Colors.red;
    if (isChanged) return Colors.amber;
    return Colors.grey.shade300;
  }

  // Get header color based on section status
  Color _getSectionHeaderColor(bool isChanged, bool isNew, bool isRemoved) {
    if (isNew) return Colors.green.withOpacity(0.15);
    if (isRemoved) return Colors.red.withOpacity(0.15);
    if (isChanged) return Colors.amber.withOpacity(0.15);
    return Colors.grey.shade100;
  }

  // Build status icon based on section status
  Widget _buildStatusIcon(bool isChanged, bool isNew, bool isRemoved) {
    if (isNew)
      return const Icon(Icons.add_circle, color: Colors.green, size: 16);
    if (isRemoved)
      return const Icon(Icons.remove_circle, color: Colors.red, size: 16);
    if (isChanged) return const Icon(Icons.edit, color: Colors.amber, size: 16);
    return const SizedBox.shrink();
  }

  // Build overall song comparison summary
  Widget _buildSummaryComparison() {
    // Calculate totals for a concise summary
    final Map<String, int> counts = {
      'sectionsAdded': 0,
      'sectionsRemoved': 0,
      'sectionsChanged': 0,
      'chordsAdded': 0,
      'chordsRemoved': 0,
      'linesAdded': 0,
      'linesRemoved': 0,
    };

    // Count added/removed sections
    for (var section in widget.newSong.sections) {
      if (_findMatchingSection(section, widget.existingSong.sections) == null) {
        counts['sectionsAdded'] = (counts['sectionsAdded'] ?? 0) + 1;
      }
    }

    for (var section in widget.existingSong.sections) {
      if (_findMatchingSection(section, widget.newSong.sections) == null) {
        counts['sectionsRemoved'] = (counts['sectionsRemoved'] ?? 0) + 1;
      }
    }

    // Count modified sections and calculate chord/line differences
    for (var existingSection in widget.existingSong.sections) {
      final newSection =
          _findMatchingSection(existingSection, widget.newSong.sections);
      if (newSection != null &&
          !_areSectionsEqual(existingSection, newSection)) {
        counts['sectionsChanged'] = (counts['sectionsChanged'] ?? 0) + 1;

        // Count line differences
        int existingLines = existingSection.lines.length;
        int newLines = newSection.lines.length;
        if (newLines > existingLines) {
          counts['linesAdded'] =
              (counts['linesAdded'] ?? 0) + (newLines - existingLines);
        } else if (existingLines > newLines) {
          counts['linesRemoved'] =
              (counts['linesRemoved'] ?? 0) + (existingLines - newLines);
        }

        // Count chord differences
        int existingChords = _countChords(existingSection);
        int newChords = _countChords(newSection);
        if (newChords > existingChords) {
          counts['chordsAdded'] =
              (counts['chordsAdded'] ?? 0) + (newChords - existingChords);
        } else if (existingChords > newChords) {
          counts['chordsRemoved'] =
              (counts['chordsRemoved'] ?? 0) + (existingChords - newChords);
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header changes
          _buildSummaryCard(
            title: 'Header Änderungen',
            content: _getHeaderDifferencesText(),
            icon: Icons.description,
            color:
                widget.existingSong.header.name != widget.newSong.header.name ||
                        widget.existingSong.header.key !=
                            widget.newSong.header.key ||
                        widget.existingSong.header.bpm !=
                            widget.newSong.header.bpm ||
                        widget.existingSong.header.timeSignature !=
                            widget.newSong.header.timeSignature ||
                        widget.existingSong.header.authors.join() !=
                            widget.newSong.header.authors.join()
                    ? Colors.amber
                    : Colors.green,
          ),

          // Section changes
          _buildSummaryCard(
            title: 'Änderungen an der Struktur',
            content: _getSectionSummaryText(counts),
            icon: Icons.view_agenda,
            color: counts['sectionsAdded']! > 0 ||
                    counts['sectionsRemoved']! > 0 ||
                    counts['sectionsChanged']! > 0
                ? Colors.amber
                : Colors.green,
          ),

          // Content changes
          _buildSummaryCard(
            title: 'Änderungen am Inhalt',
            content: _getContentSummaryText(counts),
            icon: Icons.music_note,
            color: counts['linesAdded']! > 0 ||
                    counts['linesRemoved']! > 0 ||
                    counts['chordsAdded']! > 0 ||
                    counts['chordsRemoved']! > 0
                ? Colors.amber
                : Colors.green,
          ),
        ],
      ),
    );
  }

  // Build a summary card with consistent styling
  Widget _buildSummaryCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Generate header differences text
  String _getHeaderDifferencesText() {
    final List<String> changes = [];

    if (widget.existingSong.header.name != widget.newSong.header.name) {
      changes.add(
          'Name geändert von "${widget.existingSong.header.name}" zu "${widget.newSong.header.name}"');
    }

    if (widget.existingSong.header.key != widget.newSong.header.key) {
      changes.add(
          'Tonart geändert von "${widget.existingSong.header.key}" zu "${widget.newSong.header.key}"');
    }

    if (widget.existingSong.header.bpm != widget.newSong.header.bpm) {
      changes.add(
          'BPM geändert von "${widget.existingSong.header.bpm ?? '-'}" zu "${widget.newSong.header.bpm ?? '-'}"');
    }

    if (widget.existingSong.header.timeSignature !=
        widget.newSong.header.timeSignature) {
      changes.add(
          'Taktart geändert von "${widget.existingSong.header.timeSignature ?? '-'}" zu "${widget.newSong.header.timeSignature ?? '-'}"');
    }

    if (widget.existingSong.header.authors.join() !=
        widget.newSong.header.authors.join()) {
      changes.add('Autoren wurden geändert');
    }

    return changes.isEmpty ? "Keine Änderungen am Header" : changes.join('\n');
  }

  // Generate section summary text
  String _getSectionSummaryText(Map<String, int> counts) {
    final List<String> changes = [];

    if (counts['sectionsAdded']! > 0) {
      changes.add('${counts['sectionsAdded']} neue Abschnitte hinzugefügt');
    }

    if (counts['sectionsRemoved']! > 0) {
      changes.add('${counts['sectionsRemoved']} Abschnitte entfernt');
    }

    if (counts['sectionsChanged']! > 0) {
      changes.add('${counts['sectionsChanged']} Abschnitte geändert');
    }

    return changes.isEmpty
        ? "Keine Änderungen an der Struktur"
        : changes.join('\n');
  }

  // Generate content summary text
  String _getContentSummaryText(Map<String, int> counts) {
    final List<String> changes = [];

    if (counts['linesAdded']! > 0) {
      changes.add('${counts['linesAdded']} neue Zeilen hinzugefügt');
    }

    if (counts['linesRemoved']! > 0) {
      changes.add('${counts['linesRemoved']} Zeilen entfernt');
    }

    if (counts['chordsAdded']! > 0) {
      changes.add('${counts['chordsAdded']} neue Akkorde hinzugefügt');
    }

    if (counts['chordsRemoved']! > 0) {
      changes.add('${counts['chordsRemoved']} Akkorde entfernt');
    }

    return changes.isEmpty ? "Keine Änderungen am Inhalt" : changes.join('\n');
  }

  // Build a comparison row for header items
  Widget _buildComparisonRow(String label, String existing, String newValue) {
    final bool isDifferent = existing != newValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDifferent
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(existing),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDifferent
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(newValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Find a matching section by title
  SongSection? _findMatchingSection(
      SongSection section, List<SongSection> sections) {
    try {
      return sections.firstWhere((s) => s.title == section.title);
    } catch (e) {
      return null;
    }
  }

  // Check if two sections are equal
  bool _areSectionsEqual(SongSection section1, SongSection section2) {
    if (section1.title != section2.title) return false;
    if (section1.lines.length != section2.lines.length) return false;

    for (int i = 0; i < section1.lines.length; i++) {
      if (!_areLinesEqual(section1.lines[i], section2.lines[i])) return false;
    }

    return true;
  }

  // Check if two lines are equal
  bool _areLinesEqual(LyricLine line1, LyricLine line2) {
    if (line1.lyrics != line2.lyrics) return false;
    if (line1.chords.length != line2.chords.length) return false;

    for (int i = 0; i < line1.chords.length; i++) {
      if (line1.chords[i].position != line2.chords[i].position ||
          line1.chords[i].value != line2.chords[i].value) {
        return false;
      }
    }

    return true;
  }
}
