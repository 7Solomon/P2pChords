import 'dart:convert';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:crypto/crypto.dart';

class SongConverter {
  // Singeltone
  static final SongConverter _instance = SongConverter._internal();
  factory SongConverter() => _instance;
  SongConverter._internal();

  late String key;
  late String title;

  /// Converts plain text with chords and lyrics to a Song object
  Song convertTextToSong(String text, String key, String title,
      {List<String> authors = const []}) {
    // Set VARS
    this.key = key;
    this.title = title;

    // Parse the text into sections
    final sections = parseSections(text);

    // Create a hash for the song
    final hash = sha256
        .convert(utf8.encode(text))
        .toString(); // Maybe use a better hash function

    // Create song header
    final header = SongHeader(
      name: title,
      key: key,
      authors: authors,
    );

    // Create the song object
    return Song(
      hash: hash,
      header: header,
      sections: sections,
    );
  }

  /// Parses text into SongSection objects
  List<SongSection> parseSections(String text) {
    final List<SongSection> sections = [];
    String? currentSectionTitle;
    List<String> currentSectionLines = [];

    // Split the text into lines and process each line
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if this is a section header (e.g., [Verse 1])
      final sectionMatch = RegExp(r'^\[(.*?)\]').firstMatch(line);

      if (sectionMatch != null) {
        // If we were already processing a section, save it
        if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
          sections.add(
            SongSection(
              title: currentSectionTitle,
              lines: processLyricLines(currentSectionLines),
            ),
          );
          currentSectionLines = [];
        }

        currentSectionTitle = sectionMatch.group(1);
      } else if (currentSectionTitle != null && line.isNotEmpty) {
        // Add the line to the current section
        currentSectionLines.add(line);
      }
    }

    // Add the last section
    if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
      sections.add(
        SongSection(
          title: currentSectionTitle,
          lines: processLyricLines(currentSectionLines),
        ),
      );
    }

    return sections;
  }

  /// Processes lines in a section to create LyricLine objects with chords
  List<LyricLine> processLyricLines(List<String> lines) {
    List<LyricLine> lyricLines = [];

    // Process pairs of lines (chord line followed by lyric line)
    for (int i = 0; i < lines.length; i++) {
      // Skip empty lines
      if (lines[i].trim().isEmpty) continue;

      // Check if this is a chord line
      if (isChordLine(lines[i]) &&
          i + 1 < lines.length &&
          !isChordLine(lines[i + 1])) {
        // This is a chord line and the next is a lyric line
        final chordLine = lines[i];
        final lyricLine = lines[i + 1];

        // Extract chords with their positions
        final chords = extractChords(chordLine, lyricLine);

        // Create LyricLine object
        lyricLines.add(
          LyricLine(
            lyrics: lyricLine,
            chords: chords,
          ),
        );

        // Skip the lyric line as we've processed it
        i++;
      } else {
        // This is just a lyric line without chords
        lyricLines.add(
          LyricLine(
            lyrics: lines[i],
            chords: [],
          ),
        );
      }
    }

    return lyricLines;
  }

  /// Checks if a line is likely a chord line
  bool isChordLine(String line) {
    // Most chord lines have chord names with spaces between them
    // Common chords are like A, Bm, C#m7, etc.
    final chordPattern = RegExp(
        r'^[\s]*([A-G][#b]?(?:maj|min|m|aug|dim|sus|add)?(?:[2-9]|[1-9][0-9])?\s*)+$');

    // Consider lines with N.C. (no chord) or * notation (e.g., F#m*)
    if (line.contains("N.C.") || RegExp(r'[A-G][#b]?\w*\*').hasMatch(line)) {
      return true;
    }

    return chordPattern.hasMatch(line);
  }

  /// Extract chords and their positions from a chord line and lyrics line
  List<Chord> extractChords(String chordLine, String lyricLine) {
    List<Chord> chords = [];
    //print('lyricLine: $lyricLine, chordLine: $chordLine');

    // Find each chord in the chord line
    final chordMatches =
        RegExp(r'([A-G][#b]?\w*(?:\*)?|N\.C\.)').allMatches(chordLine);
    //print('chordMatches: $chordMatches');
    for (final match in chordMatches) {
      final chordText = match.group(0)!;
      //final chordvalue =
      int chordPosition = match.start;
      String nashvilleValue = ChordUtils.chordToNashville(chordText, key);
      //int lyricPosition =
      //    findChordPositionInLyrics(chordPosition, lyricLine, chordLine);
      //
      // Add chord
      chords.add(Chord(
        position: chordPosition,
        value: chordText,
      ));
    }

    return chords;
  }

  /// Find the correct position for a chord in the lyrics
//int findChordPositionInLyrics(
//    int chordPosition, String lyricLine, String chordLine) {
//  // If the chord is at the beginning of the chord line, place it at the beginning of lyrics
//  if (chordPosition == 0 ||
//      chordLine.substring(0, chordPosition).trim().isEmpty) {
//    return 0;
//  }
//
//  // Count visible characters (not spaces) in chord line before the chord
//  int visibleCharsBefore =
//      chordLine.substring(0, chordPosition).replaceAll(' ', '').length;
//
//  // Find position in lyrics that most closely matches
//  int lyricPos = 0;
//  int charCount = 0;
//
//  // Try to align with visible characters in lyrics
//  for (int i = 0; i < lyricLine.length; i++) {
//    if (lyricLine[i] != ' ') {
//      charCount++;
//    }
//    if (charCount >= visibleCharsBefore) {
//      lyricPos = i;
//      break;
//    }
//  }
//
//  return lyricPos;
//}

  /// Convert standard text format to the JSON structure similar to test.json
//Map<String, dynamic> convertTextToJsonFormat(String text,
//    {String title = 'Untitled') {
//  final song = convertTextToSong(text, title: title, key: key);
//
//  // Convert to map structure
//  final Map<String, dynamic> result = {
//    'header': song.header.toMap(),
//    'data': {}
//  };
//
//  // Process each section
//  for (var section in song.sections) {
//    final sectionKey = normalizeSectionKey(section.title);
//    result['data'][sectionKey] =
//        section.lines.map((line) => line.toMap()).toList();
//  }
//
//  return result;
//}

  /// Normalize section title to a key format (e.g. "Verse 1" to "verse1")
  String normalizeSectionKey(String title) {
    // Remove any non-alphanumeric characters, convert to lowercase
    final normalized =
        title.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Extract number if present (e.g., "verse1")
    final match = RegExp(r'([a-z]+)(\d*)').firstMatch(normalized);
    if (match != null) {
      final base = match.group(1);
      final number = match.group(2);
      return base! + (number ?? '');
    }

    return normalized;
  }

  /// Converts chord notation to Nashville notation based on the key
  List<Chord> convertChordsToNashville(List<Chord> chords, String key) {
    return chords.map((chord) {
      return Chord(
        position: chord.position,
        value: ChordUtils.chordToNashville(chord.value, key),
      );
    }).toList();
  }

  /// Parse potential header information from the beginning of text
  SongHeader extractHeaderInfo(String text) {
    List<String> authors = [];

    // Simple regex patterns for common header formats
    final titleMatch =
        RegExp(r'Title:\s*(.+)$', multiLine: true).firstMatch(text);
    final keyMatch =
        RegExp(r'Key:\s*([A-G][#b]?)$', multiLine: true).firstMatch(text);
    final authorMatch =
        RegExp(r'Author(?:s)?:\s*(.+)$', multiLine: true).firstMatch(text);

    if (titleMatch != null) title = titleMatch.group(1)!.trim();
    if (keyMatch != null) key = keyMatch.group(1)!.trim();
    if (authorMatch != null) {
      authors = authorMatch.group(1)!.split(',').map((a) => a.trim()).toList();
    }

    return SongHeader(
      name: title,
      key: key,
      authors: authors,
    );
  }
}

final converter = SongConverter();
