import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/converter/components.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

class ConversionReviewPage extends StatefulWidget {
  final String title;
  final String artist;
  final String originalText;

  const ConversionReviewPage({
    Key? key,
    required this.title,
    required this.artist,
    required this.originalText,
  }) : super(key: key);

  @override
  State<ConversionReviewPage> createState() => _ConversionReviewPageState();
}

class _ConversionReviewPageState extends State<ConversionReviewPage> {
  Song? _convertedSong;
  String _key = 'C'; // Default key
  bool _isConverting = false;
  String _error = '';

  // Map to track chord-lyric line associations
  Map<String, int?> _chordToLyricLineMap = {};

  final List<String> _keyOptions = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
    'Cm',
    'C#m',
    'Dm',
    'D#m',
    'Em',
    'Fm',
    'F#m',
    'Gm',
    'G#m',
    'Am',
    'A#m',
    'Bm'
  ];

  @override
  void initState() {
    super.initState();
    // Perform initial conversion
    _convertSong();
  }

  void _convertSong() {
    setState(() {
      _isConverting = true;
      _error = '';
    });

    try {
      final convertedSong = converter.convertTextToSong(
        widget.originalText,
        _key,
        widget.title,
        authors: [widget.artist],
      );

      setState(() {
        _convertedSong = convertedSong;
        _isConverting = false;
        _initializeAssociations();
      });
    } catch (e) {
      setState(() {
        _error = 'Conversion error: ${e.toString()}';
        _isConverting = false;
      });
    }
  }

  // Initialize chord-lyric line associations based on the converter's output
  void _initializeAssociations() {
    if (_convertedSong == null) return;

    _chordToLyricLineMap = {};

    for (int sectionIndex = 0;
        sectionIndex < _convertedSong!.sections.length;
        sectionIndex++) {
      final section = _convertedSong!.sections[sectionIndex];

      for (int lineIndex = 0; lineIndex < section.lines.length; lineIndex++) {
        final line = section.lines[lineIndex];

        // If this is a chord line, try to find an association
        if (line.chords.isNotEmpty) {
          // In the current logic, chord lines are often followed by lyric lines
          // So we'll associate with the next line if it exists and is a lyric line
          if (lineIndex + 1 < section.lines.length &&
              section.lines[lineIndex + 1].chords.isEmpty) {
            _chordToLyricLineMap['$sectionIndex:$lineIndex'] = lineIndex + 1;
          }
        }
      }
    }
  }

  void _updateSectionTitle(int sectionIndex, String newTitle) {
    if (_convertedSong == null) return;

    setState(() {
      final updatedSections = List<SongSection>.from(_convertedSong!.sections);
      updatedSections[sectionIndex] = SongSection(
        title: newTitle,
        lines: _convertedSong!.sections[sectionIndex].lines,
      );

      _convertedSong = Song(
        hash: _convertedSong!.hash,
        header: _convertedSong!.header,
        sections: updatedSections,
      );
    });
  }

  void _updateLyricLine(int sectionIndex, int lineIndex, String newLyrics) {
    if (_convertedSong == null) return;

    setState(() {
      final section = _convertedSong!.sections[sectionIndex];
      final updatedLines = List<LyricLine>.from(section.lines);

      updatedLines[lineIndex] = LyricLine(
        lyrics: newLyrics,
        chords: section.lines[lineIndex].chords,
      );

      final updatedSections = List<SongSection>.from(_convertedSong!.sections);
      updatedSections[sectionIndex] = SongSection(
        title: section.title,
        lines: updatedLines,
      );

      _convertedSong = Song(
        hash: _convertedSong!.hash,
        header: _convertedSong!.header,
        sections: updatedSections,
      );
    });
  }

  void _updateChord(
      int sectionIndex, int lineIndex, int chordIndex, String newValue) {
    if (_convertedSong == null) return;

    setState(() {
      final section = _convertedSong!.sections[sectionIndex];
      final line = section.lines[lineIndex];

      final updatedChords = List<Chord>.from(line.chords);
      updatedChords[chordIndex] = Chord(
        position: line.chords[chordIndex].position,
        value: newValue,
      );

      final updatedLines = List<LyricLine>.from(section.lines);
      updatedLines[lineIndex] = LyricLine(
        lyrics: line.lyrics,
        chords: updatedChords,
      );

      final updatedSections = List<SongSection>.from(_convertedSong!.sections);
      updatedSections[sectionIndex] = SongSection(
        title: section.title,
        lines: updatedLines,
      );

      _convertedSong = Song(
        hash: _convertedSong!.hash,
        header: _convertedSong!.header,
        sections: updatedSections,
      );
    });
  }

  // Change line type between chord and lyric
  void _updateLineType(int sectionIndex, int lineIndex, LineType newType) {
    if (_convertedSong == null) return;

    setState(() {
      final section = _convertedSong!.sections[sectionIndex];
      final line = section.lines[lineIndex];

      // Convert to new line type
      LyricLine updatedLine;

      if (newType == LineType.chord && line.chords.isEmpty) {
        // Convert lyric line to chord line
        // Create chord from text
        updatedLine = LyricLine(
          lyrics: line.lyrics,
          chords: [Chord(position: 0, value: line.lyrics)], // Simple example
        );
      } else if (newType == LineType.lyric && line.chords.isNotEmpty) {
        // Convert chord line to lyric line
        updatedLine = LyricLine(
          lyrics: line.lyrics.isEmpty
              ? line.chords.map((c) => c.value).join(' ')
              : line.lyrics,
          chords: [],
        );
      } else {
        // No change needed
        return;
      }

      // Update the song
      final updatedLines = List<LyricLine>.from(section.lines);
      updatedLines[lineIndex] = updatedLine;

      final updatedSections = List<SongSection>.from(_convertedSong!.sections);
      updatedSections[sectionIndex] = SongSection(
        title: section.title,
        lines: updatedLines,
      );

      _convertedSong = Song(
        hash: _convertedSong!.hash,
        header: _convertedSong!.header,
        sections: updatedSections,
      );

      // Update associations
      if (newType == LineType.lyric) {
        // If changed to lyric, remove any associations to this line
        _chordToLyricLineMap.removeWhere((key, value) =>
            value == lineIndex && key.startsWith('$sectionIndex:'));
      }
    });
  }

  // Update association between chord line and lyric line
  void _updateChordLineAssociation(
      int sectionIndex, int chordLineIndex, int? lyricLineIndex) {
    setState(() {
      _chordToLyricLineMap['$sectionIndex:$chordLineIndex'] = lyricLineIndex;
    });
  }

  void _saveSong() {
    // Process the song with associations before saving
    if (_convertedSong != null) {
      _processAssociationsForSave();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Song would be saved with updated associations')),
      );
      Navigator.pop(context);
    }
  }

  // Process the associations to create the final song structure
  void _processAssociationsForSave() {
    if (_convertedSong == null) return;

    // This is a placeholder for the actual implementation
    print('Associations for saving:');
    _chordToLyricLineMap.forEach((key, value) {
      print('Chord line $key is associated with lyric line $value');
    });
    print('NOT IMPLEMENTED: Saving the song with associations...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversion Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _convertedSong != null ? _saveSong : null,
            tooltip: 'Save song',
          ),
        ],
      ),
      body: _isConverting
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _convertSong,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildReviewContent(),
    );
  }

  Widget _buildReviewContent() {
    if (_convertedSong == null) {
      return const Center(child: Text('No conversion data available'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Song: ${_convertedSong!.header.name}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Key: '),
              DropdownButton<String>(
                value: _key,
                items: _keyOptions.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(key),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _key = newValue;
                    });
                    _convertSong();
                  }
                },
              ),
            ],
          ),
        ),

        // Tab view for Original and Converted views
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Original Text'),
                    Tab(text: 'Converted Result'),
                  ],
                  labelColor: Colors.blue,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Original text tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SelectableText(
                            widget.originalText,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      // Converted result tab
                      _buildConvertedView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConvertedView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        for (int sectionIndex = 0;
            sectionIndex < _convertedSong!.sections.length;
            sectionIndex++)
          SectionCard(
            section: _convertedSong!.sections[sectionIndex],
            sectionIndex: sectionIndex,
            onSectionTitleChanged: _updateSectionTitle,
            onLineTypeChanged: _updateLineType,
            onChordLineAssociationChanged: _updateChordLineAssociation,
            onLyricsChanged: _updateLyricLine,
            onChordChanged: _updateChord,
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveSong,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: const Text('Save Song'),
        ),
      ],
    );
  }
}
