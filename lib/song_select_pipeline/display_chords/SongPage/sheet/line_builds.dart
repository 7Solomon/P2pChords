import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/provider/sheet_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

class LineSegment {
  final String text;
  final List<Chord> chords;
  final int startIndex;

  LineSegment(this.text, this.chords, this.startIndex);
}

class LineBuildFunction {
  final BuildContext context;

  LineBuildFunction(this.context);

  UiVariables get uiVariables =>
      Provider.of<SheetUiProvider>(context, listen: false).uiVariables;
  String? get currentSongHash =>
      Provider.of<CurrentSelectionProvider>(context, listen: false)
          .currentSongHash;
  String? get currentKey => Provider.of<SheetUiProvider>(context, listen: false)
      .getCurrentKeyForSong(currentSongHash ?? 'KÖNNTE FEHLER SEIN');

  // Helper to create TextPainter with consistent style
  TextPainter _createTextPainter(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout(
        maxWidth: double.infinity); // Layout with infinite width initially
  }

  Widget buildLine(LineData line) {
    // If no chords, just return the lyrics
    if (line.chords.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: uiVariables.lineSpacing.value),
        child: Text(
          line.lyrics,
          style: TextStyle(
            fontSize: uiVariables.fontSize.value,
            fontFamily: 'Roboto Mono', // Ensure consistent font
            height: 1.3, // Adjust line height if needed
          ),
        ),
      );
    }

    // Handle chord-only lines by reusing the buildChordLyricLine logic
    if (line.lyrics.isEmpty) {
      if (line.chords.isEmpty) return const SizedBox.shrink();

      // Sort chords by position to build the line correctly
      final sortedChords = List<Chord>.from(line.chords)
        ..sort((a, b) => a.position.compareTo(b.position));

      // This ensures correct spacing for variable-length chord names.
      final buffer = StringBuffer();
      int currentPos = 0;
      for (final chord in sortedChords) {
        final chordText = translateChord(chord);
        if (chord.position > currentPos) {
          buffer.write(' ' * (chord.position - currentPos));
        }
        buffer.write(chordText);
        currentPos = chord.position + chordText.length;
      }

      final dummyLyrics = buffer.toString();
      final dummyLineData = LineData(lyrics: dummyLyrics, chords: line.chords);

      // Call the standard builder but disable lyric rendering
      return Padding(
        padding: EdgeInsets.only(bottom: uiVariables.lineSpacing.value),
        child: buildChordLyricLine(dummyLineData, renderLyrics: false),
      );
    }

    // Process line with chords using the new Stack method
    return Padding(
      padding: EdgeInsets.only(bottom: uiVariables.lineSpacing.value),
      child: buildChordLyricLine(line),
    );
  }

  Widget buildChordLyricLine(LineData line, {bool renderLyrics = true}) {
    final lyricStyle = TextStyle(
      fontSize: uiVariables.fontSize.value,
      fontFamily: 'Roboto Mono', 
      height: 1.3, // Match lyric Text height
    );
    final chordStyle = TextStyle(
      fontSize: uiVariables.fontSize.value - 2, // Smaller for chords
      color: Colors.blue.shade700,
      fontFamily: 'Roboto Mono', // IMPORTANT: Use the same font
      height: 1.0,
    );

    return LayoutBuilder(builder: (context, constraints) {
      // Split lyrics into lines based on available width
      // Ensure splitIntoLines uses a TextPainter with the correct lyricStyle
      final List<LineSegment> segments =
          splitIntoLines(line, constraints.maxWidth, lyricStyle);

      // Build a Stack for each segment
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((segment) {
          // Create and layout TextPainter for this specific segment's lyrics
          final painter = _createTextPainter(segment.text, lyricStyle);
          painter.layout(
              maxWidth: constraints.maxWidth); // Layout with constraint

          // Calculate the height needed for lyrics + chords above
          final chordHeightEstimate =
              (chordStyle.fontSize ?? 14) * (chordStyle.height ?? 1.2);
          final lyricHeight = renderLyrics ? painter.height : 0;
          final totalSegmentHeight = lyricHeight + chordHeightEstimate + 4;

          return SizedBox(
            width: constraints.maxWidth, // Constrain width
            height: totalSegmentHeight, // Set calculated height
            child: Stack(
              clipBehavior:
                  Clip.none, // Allow positioned chords to be slightly outside
              children: [
                // 1. Lyric Text (at the bottom of the Stack space)
                if (renderLyrics)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0, // Align lyrics to the bottom
                    height: painter.height, // Explicit height
                    child: Text(
                      segment.text,
                      style: lyricStyle,
                      maxLines: 1, // Should already be handled by splitIntoLines
                      overflow: TextOverflow.clip,
                    ),
                  ),

                // 2. Positioned Chords (above the lyrics)
                ...segment.chords.map((chord) {
                  // Calculate position relative to the start of the segment
                  final int relativePos = chord.position - segment.startIndex;

                  if (relativePos < 0 || relativePos > segment.text.length) {
                    // Chord is outside this segment's text range
                    //print(
                    //    "WARNING: Chord ${chord.value} outside segment range");
                    return const Positioned(
                        child: SizedBox.shrink()); // Render nothing
                  }

                  // Get the X offset using the painter for this segment
                  final double xOffset = painter
                      .getOffsetForCaret(
                        ui.TextPosition(offset: relativePos),
                        ui.Rect.zero, // Caret prototype is zero
                      )
                      .dx;

                  // Translate chord if needed
                  final String displayChord = translateChord(chord);

                  return Positioned(
                    left: xOffset,
                    top: 0, // Place chords at the top of the Stack space
                    child: Text(
                      displayChord,
                      style: chordStyle,
                      softWrap: false,
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  // --- Helper function to translate chord (if needed) ---
  String translateChord(Chord chord) {
    String chordName =
        ChordUtils.nashvilleToChord(chord.value, currentKey ?? 'C');
    
    return chordName;
  }

  // --- Ensure splitIntoLines uses TextPainter with the correct style ---
  List<LineSegment> splitIntoLines(
      LineData line, double maxWidth, TextStyle style) {
    final List<LineSegment> segments = [];
    if (line.lyrics.isEmpty) return segments;

    final painter = _createTextPainter(line.lyrics, style);
    painter.layout(maxWidth: maxWidth); // Layout with the constraint

    final lineMetrics = painter.computeLineMetrics();
    int currentStartIndex = 0;

    for (final metric in lineMetrics) {
      final int endIndex = painter
          .getPositionForOffset(Offset(metric.width, metric.baseline))
          .offset;
      // Ensure endIndex doesn't exceed lyrics length, especially for the last line
      final int safeEndIndex =
          endIndex.clamp(currentStartIndex, line.lyrics.length);

      final segmentText =
          line.lyrics.substring(currentStartIndex, safeEndIndex);

      // Find chords within this segment's character range
      final segmentChords = line.chords.where((chord) {
        return chord.position >= currentStartIndex &&
            chord.position < safeEndIndex;
      }).toList();

      segments.add(LineSegment(segmentText, segmentChords, currentStartIndex));
      currentStartIndex = safeEndIndex; // Move start index for the next line
      // Break if we've processed the whole string (important for last line)
      if (currentStartIndex >= line.lyrics.length) break;
    }

    // Handle potential empty last segment if lyrics end exactly at line break
    if (currentStartIndex < line.lyrics.length) {
      final segmentText = line.lyrics.substring(currentStartIndex);
      final segmentChords = line.chords.where((chord) {
        return chord.position >= currentStartIndex;
      }).toList();
      if (segmentText.isNotEmpty || segmentChords.isNotEmpty) {
        segments
            .add(LineSegment(segmentText, segmentChords, currentStartIndex));
      }
    }

    return segments;
  }
}
