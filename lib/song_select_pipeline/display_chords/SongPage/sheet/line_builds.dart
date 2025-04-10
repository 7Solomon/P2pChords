import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

class LineSegment {
  final String text;
  final List<Chord> chords;
  final int startIndex;

  LineSegment(this.text, this.chords, this.startIndex);
}

class LineBuildFunction {
  final BuildContext context;

  final UiVariables uiVariables;
  final String currentKey;

  LineBuildFunction(this.context, this.uiVariables, this.currentKey);

  Widget buildLine(LyricLine line) {
    // If no chords, just return the lyrics
    if (line.chords.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: uiVariables.lineSpacing.value),
        child: Text(
          line.lyrics,
          style: TextStyle(fontSize: uiVariables.fontSize.value),
        ),
      );
    }

    // Process line with chords
    return Padding(
      padding: EdgeInsets.only(bottom: uiVariables.lineSpacing.value),
      child: buildChordLyricLine(line),
    );
  }

  Widget buildChordLyricLine(LyricLine line) {
    return LayoutBuilder(builder: (context, constraints) {
      // Split lyrics into lines based on available width
      final List<LineSegment> segments =
          splitIntoLines(line, constraints.maxWidth);

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
                            buildChordSegment(segment, constraints.maxWidth),
                      ),
                    ),
                  ),
                  // Lyric line for this segment
                  Text(
                    segment.text,
                    style: TextStyle(fontSize: uiVariables.fontSize.value),
                  ),
                ])
            .toList(),
      );
    });
  }

// Split lyrics into lines that fit within the available width
  List<LineSegment> splitIntoLines(LyricLine line, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: line.lyrics,
        style: TextStyle(fontSize: uiVariables.fontSize.value),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: maxWidth);

    final List<LineSegment> segments = [];
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
        segments.add(createSegment(line, lineStart, i));

        lineStart = i;
        currentY = boxes[i].top;
      }
    }

    // Add the final segment
    if (lineStart < line.lyrics.length) {
      segments.add(createSegment(line, lineStart, line.lyrics.length));
    }

    return segments;
  }

// Create a segment with its corresponding chords
  LineSegment createSegment(LyricLine line, int start, int end) {
    final text = line.lyrics.substring(start, end);

    // Find chords that belong to this segment
    final chords = line.chords.where((chord) {
      return chord.position >= start && chord.position < end;
    }).map((chord) {
      // Adjust chord position relative to segment start
      return Chord(value: chord.value, position: chord.position - start);
    }).toList();

    return LineSegment(text, chords, start);
  }

// Build chord widgets for a given line segment
  List<Widget> buildChordSegment(LineSegment segment, double maxWidth) {
    // Add maxWidth parameter
    if (segment.chords.isEmpty) {
      return [
        SizedBox(height: uiVariables.fontSize.value - 2)
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
        double spaceWidth =
            getTextWidth(spaceBefore, uiVariables.fontSize.value);

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
          getTextWidth(translateChord(chord), uiVariables.fontSize.value - 2);

      // Check if adding this chord would exceed available width
      if (currentWidth + chordWidth > maxWidth - 10) {
        // Leave 10px safety margin
        break; // Stop adding this chord if it would overflow
      }

      // Add chord text
      result.add(
        Text(
          translateChord(chord),
          style: TextStyle(
            fontSize: uiVariables.fontSize.value - 2,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );

      currentWidth += chordWidth;
      lastPos = chord.position;
    }

    // Add flexible spacer at the end to fill remaining space
    result.add(const Spacer());

    return result;
  }

// Helper to get text width
  double getTextWidth(String text, double fontSize) {
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
  String translateChord(Chord chord) {
    String chordString = ChordUtils.nashvilleToChord(chord.value, currentKey);
    return chordString;
  }
}
