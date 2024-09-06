import 'package:flutter/material.dart';

class LyricsWithChords extends StatelessWidget {
  final String lyrics;
  final Map<String, String> chords;

  const LyricsWithChords({super.key, required this.lyrics, required this.chords});

  @override
  Widget build(BuildContext context) {
    // Convert string keys to integers
    final Map<int, String> intChords =
        chords.map((key, value) => MapEntry(int.parse(key), value));

    // Calculate the height needed for both chords and lyrics
    final textPainter = TextPainter(
      text: TextSpan(text: lyrics, style: const TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final totalHeight = textPainter.height + 30; // 30 for chord height

    return CustomPaint(
      painter: ChordPainter(lyrics: lyrics, chords: intChords),
      size: Size(double.infinity, totalHeight),
    );
  }
}

class ChordPainter extends CustomPainter {
  final String lyrics;
  final Map<int, String> chords;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;

  ChordPainter({
    required this.lyrics,
    required this.chords,
    this.lyricStyle = const TextStyle(fontSize: 16, color: Colors.black),
    this.chordStyle = const TextStyle(fontSize: 14, color: Colors.blue),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create TextPainter for lyrics
    final lyricPainter = TextPainter(
      text: TextSpan(text: lyrics, style: lyricStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    lyricPainter.layout(maxWidth: size.width);

    // Create TextPainter for chords
    final chordPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    double yOffset = 0; // Y position to start painting lyrics
    final double lineHeight =
        lyricPainter.height / lyrics.split('\n').length; // Line height
    const double lineSpacing = 4; // Spacing between lines
    double chordYOffset = 0; // Y position for chords

    // Paint lyrics
    lyricPainter.paint(canvas, Offset(0, yOffset));

    // Split lyrics into lines
    final lines = lyrics.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Adjust chordYOffset to account for line height and spacing
      chordYOffset = yOffset + i * (lineHeight + lineSpacing);

      // Find the chord positions in the line
      chords.forEach((index, chord) {
        if (index >= line.length) return; // Ignore indices out of line length

        final chordOffset = lyricPainter.getOffsetForCaret(
          TextPosition(offset: index),
          Rect.zero,
        );

        chordPainter.text = TextSpan(text: chord, style: chordStyle);
        chordPainter.layout();
        chordPainter.paint(
            canvas, Offset(chordOffset.dx, chordYOffset - chordPainter.height));
      });

      // Move to the next line
      yOffset += lineHeight + lineSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
