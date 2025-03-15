import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/chord_painter.dart';
import 'package:flutter/material.dart';

class _LineSegment {
  final String text;
  final List<Chord> chords;
  final int startIndex;

  _LineSegment(this.text, this.chords, this.startIndex);
}

class SongSheetDisplay extends StatefulWidget {
  final Song song;
  final String currentKey;
  final double startFontSize;
  final Function(int) onSectionChanged;

  const SongSheetDisplay({
    super.key,
    required this.song,
    required this.currentKey,
    required this.startFontSize,
    required this.onSectionChanged,
  });

  @override
  State<SongSheetDisplay> createState() => _SongSheetDisplayState();
}

class _SongSheetDisplayState extends State<SongSheetDisplay> {
  late PageController _pageController;
  int _currentPage = 0;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.startFontSize;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleScreenTap(BuildContext context, TapDownDetails details) {
    // Determine if tap is in top or bottom half of screen
    final screenHeight = MediaQuery.of(context).size.height;
    final tapPosition = details.globalPosition.dy;

    if (tapPosition < screenHeight / 2) {
      // Tap on top half - go to next page
      if (_currentPage > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Tap on bottom half - go to previous page
      if (_currentPage < widget.song.sections.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Song header
        _buildSongHeader(),

        // Main content
        Expanded(
          child: GestureDetector(
            onTapDown: (details) => _handleScreenTap(context, details),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.song.sections.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                widget.onSectionChanged(index);
              },
              itemBuilder: (context, index) {
                return _buildSection(widget.song.sections[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.song.header.name,
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
          // Small page indicator
          const SizedBox(width: 12),
          Text(
            '${_currentPage + 1}/${widget.song.sections.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(SongSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title.toUpperCase(),
            style: TextStyle(
              fontSize: _fontSize + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...section.lines.map((line) => _buildLyricLine(line)),
        ],
      ),
    );
  }

  Widget _buildLyricLine(LyricLine line) {
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
      double chordWidth =
          _getTextWidth(_translateChord(chord.value), _fontSize - 2);

      // Check if adding this chord would exceed available width
      if (currentWidth + chordWidth > maxWidth - 10) {
        // Leave 10px safety margin
        break; // Stop adding this chord if it would overflow
      }

      // Add chord text
      result.add(
        Text(
          _translateChord(chord.value),
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
  String _translateChord(String chord) {
    // Implement your chord translation logic here
    return chord;
  }
}
