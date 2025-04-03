import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/helper.dart';
import 'package:flutter/material.dart';

class _LineSegment {
  final String text;
  final List<Chord> chords;
  final int startIndex;

  _LineSegment(this.text, this.chords, this.startIndex);
}

class SongSheetDisplay extends StatefulWidget {
  final List<Song> songs;
  final int songIndex;
  final int sectionIndex;
  final String currentKey;
  final double startFontSize;
  final double startMinColumnWidth;
  final int startSectionCount;
  final Function(int) onSectionChanged;
  final Function(int) onSongChanged;

  const SongSheetDisplay({
    super.key,
    required this.songs,
    required this.songIndex,
    required this.sectionIndex,
    required this.currentKey,
    required this.startFontSize,
    required this.startMinColumnWidth,
    required this.startSectionCount,
    required this.onSectionChanged,
    required this.onSongChanged,
  });

  @override
  State<SongSheetDisplay> createState() => _SongSheetDisplayState();
}

class _SongSheetDisplayState extends State<SongSheetDisplay> {
  late int _currentSectionIndex;
  late int _currentSongIndex;
  late double _fontSize;
  late double _minColumnWidth;
  late List<SongSection> _sections;

  Song get currentSong => widget.songs[_currentSongIndex];

  @override
  void initState() {
    super.initState();
    _fontSize = widget.startFontSize;

    _minColumnWidth = widget.startMinColumnWidth;
    _currentSectionIndex = widget.sectionIndex;
    _currentSongIndex = widget.songIndex;
    _loadSections();
  }

  @override
  void didUpdateWidget(SongSheetDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for section changes
    if (widget.sectionIndex != _currentSectionIndex) {
      setState(() {
        _currentSectionIndex = widget.sectionIndex;
      });
    }

    // Check for song changes
    if (oldWidget.songIndex != widget.songIndex ||
        oldWidget.songs != widget.songs) {
      _currentSongIndex = widget.songIndex;
      _loadSections();
    }
  }

  void _loadSections() {
    _sections = currentSong.sections;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleScreenTap(BuildContext context, TapDownDetails details) {
    // Determine if tap is in top or bottom half of screen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPositionY = details.globalPosition.dy;
    final tapPositionX = details.globalPosition.dx;

    if (tapPositionX > screenWidth / 2) {
      // Tap on right half
      setState(() {
        //openSongDrawer();
      });
    }

    if (tapPositionY < screenHeight / 2) {
      // Tap on top half - go to previous section
      if (_currentSectionIndex > 0) {
        setState(() {
          _currentSectionIndex--;
          widget.onSectionChanged(_currentSectionIndex);
        });
      } else if (_currentSongIndex > 0) {
        // Move to previous song
        setState(() {
          _currentSongIndex--;
          _loadSections();
          _currentSectionIndex = _sections.length - 1;
          widget.onSongChanged(_currentSongIndex);
        });
      }
    } else {
      // Tap on bottom half - go to next section
      if (_currentSectionIndex < _sections.length - 1) {
        setState(() {
          _currentSectionIndex++;
          widget.onSectionChanged(_currentSectionIndex);
        });
      } else if (_currentSongIndex < widget.songs.length - 1) {
        // Move to next song
        setState(() {
          _currentSongIndex++;
          _loadSections();
          _currentSectionIndex = 0;
          widget.onSongChanged(_currentSongIndex);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleScreenTap(context, details),
      child: Column(
        children: [
          // Song header
          _buildSongHeader(),

          Expanded(
            child: AnimatedSectionView(
              sections: _sections,
              currentIndex: _currentSectionIndex,
              sectionsPerView: widget.startSectionCount,
              fontSize: _fontSize,
              minColumnWidth: _minColumnWidth,
              buildSection: (section, fontSize) {
                return SectionBuilder.buildSection(
                  section,
                  fontSize,
                  (line) => _buildLine(line),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              currentSong.header.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Key: ${widget.currentKey}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          // Page indicator with song number
          const SizedBox(width: 12),
          Text(
            'Section ${_currentSectionIndex + 1}/${_sections.length} • Song ${_currentSongIndex + 1}/${widget.songs.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  //Widget _buildSectionView(int currentIndex) {
  //  // Calculate how many sections to display
  //  List<SongSection> sectionsToShow = [];
//
  //  // Add current section and subsequent sections up to startSectionCount
  //  for (int i = currentIndex;
  //      i < currentIndex + widget.startSectionCount && i < _sections.length;
  //      i++) {
  //    sectionsToShow.add(_sections[i]);
  //  }
//
  //  return SingleChildScrollView(
  //    physics:
  //        const NeverScrollableScrollPhysics(), // Disable scrolling within the page
  //    padding: const EdgeInsets.all(16.0),
  //    child: Column(
  //      crossAxisAlignment: CrossAxisAlignment.start,
  //      children: [
  //        ...sectionsToShow.expand((section) => [
  //              Text(
  //                section.title.toUpperCase(),
  //                style: TextStyle(
  //                  fontSize: _fontSize + 2,
  //                  fontWeight: FontWeight.bold,
  //                ),
  //              ),
  //              const SizedBox(height: 16),
  //              ...section.lines.map((line) => _buildLine(line)),
  //              const SizedBox(height: 24),
  //            ]),
  //      ],
  //    ),
  //  );
  //}

  Widget _buildLine(LyricLine line) {
    // If no chords, just return the lyrics
    if (line.chords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          line.lyrics,
          style: TextStyle(fontSize: _fontSize),
        ),
      );
    }

    // Process line with chords
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildChordLyricLine(line),
    );
  }

  Widget _buildChordLyricLine(LyricLine line) {
    return LayoutBuilder(builder: (context, constraints) {
      // Split lyrics into lines based on available width
      final List<_LineSegment> segments =
          _splitIntoLines(line, constraints.maxWidth);

      // Build a chord line + lyric line for each segment
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments
            .expand((segment) => [
                  // Chord line for this segment (with overflow protection)
                  SizedBox(
                    width: constraints.maxWidth,
                    child: ClipRect(
                      // Add ClipRect to ensure no overflow
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _buildChordSegment(segment, constraints.maxWidth),
                      ),
                    ),
                  ),
                  // Lyric line for this segment
                  Text(
                    segment.text,
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ])
            .toList(),
      );
    });
  }

  // Split lyrics into lines that fit within the available width
  List<_LineSegment> _splitIntoLines(LyricLine line, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: line.lyrics,
        style: TextStyle(fontSize: _fontSize),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: maxWidth);

    final List<_LineSegment> segments = [];
    final List<TextBox> boxes = [];

    // Get all line boxes
    for (int i = 0; i < line.lyrics.length; i++) {
      final lineBoxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );

      if (lineBoxes.isNotEmpty) {
        boxes.add(lineBoxes.first);
      }
    }

    // Find line breaks by detecting y-coordinate changes
    int lineStart = 0;
    double currentY = boxes.isNotEmpty ? boxes.first.top : 0;

    for (int i = 1; i < boxes.length; i++) {
      if (boxes[i].top > currentY + 1) {
        // New line detected (allowing for small floating point differences)
        // Create a segment for the current line
        segments.add(_createSegment(line, lineStart, i));

        lineStart = i;
        currentY = boxes[i].top;
      }
    }

    // Add the final segment
    if (lineStart < line.lyrics.length) {
      segments.add(_createSegment(line, lineStart, line.lyrics.length));
    }

    return segments;
  }

  // Create a segment with its corresponding chords
  _LineSegment _createSegment(LyricLine line, int start, int end) {
    final text = line.lyrics.substring(start, end);

    // Find chords that belong to this segment
    final chords = line.chords.where((chord) {
      return chord.position >= start && chord.position < end;
    }).map((chord) {
      // Adjust chord position relative to segment start
      return Chord(value: chord.value, position: chord.position - start);
    }).toList();

    return _LineSegment(text, chords, start);
  }

  // Build chord widgets for a given line segment
  List<Widget> _buildChordSegment(_LineSegment segment, double maxWidth) {
    // Add maxWidth parameter
    if (segment.chords.isEmpty) {
      return [
        SizedBox(height: _fontSize - 2)
      ]; // Empty chord line with some height
    }

    List<Widget> result = [];
    int lastPos = 0;
    double currentWidth = 0.0; // Track used width

    // Sort chords by position
    final sortedChords = [...segment.chords]
      ..sort((a, b) => a.position.compareTo(b.position));

    for (var chord in sortedChords) {
      // Add space before chord
      if (chord.position > lastPos) {
        String spaceBefore = segment.text.substring(lastPos, chord.position);
        double spaceWidth = _getTextWidth(spaceBefore, _fontSize);

        // Check if adding this space would exceed available width
        if (currentWidth + spaceWidth > maxWidth - 10) {
          // Leave 10px safety margin
          break; // Stop adding more chords if we're about to overflow
        }

        result.add(SizedBox(width: spaceWidth));
        currentWidth += spaceWidth;
      }

      // Calculate chord width
      double chordWidth = _getTextWidth(_translateChord(chord), _fontSize - 2);

      // Check if adding this chord would exceed available width
      if (currentWidth + chordWidth > maxWidth - 10) {
        // Leave 10px safety margin
        break; // Stop adding this chord if it would overflow
      }

      // Add chord text
      result.add(
        Text(
          _translateChord(chord),
          style: TextStyle(
            fontSize: _fontSize - 2,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );

      currentWidth += chordWidth;
      lastPos = chord.position;
    }

    // Add flexible spacer at the end to fill remaining space
    result.add(Spacer());

    return result;
  }

  // Helper to get text width
  double _getTextWidth(String text, double fontSize) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  // Translate chord if needed
  String _translateChord(Chord chord) {
    String chordString =
        ChordUtils.nashvilleToChord(chord.value, widget.currentKey);
    return chordString;
  }
}
