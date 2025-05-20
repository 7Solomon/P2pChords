import 'dart:convert';
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:crypto/crypto.dart';

// Class to represent the preliminary parsing state
class PreliminarySongData {
  final String originalText;
  final List<PreliminarySection> sections;
  final String title;
  final List<String> authors;
  final String key;

  PreliminarySongData({
    required this.originalText,
    required this.sections,
    required this.title,
    this.authors = const [],
    this.key = '',
  });
}

// Class to represent a section before final processing
class PreliminarySection {
  String title;
  List<PreliminaryLine> lines;

  PreliminarySection({
    required this.title,
    required this.lines,
  });
}

// Class to represent a line before final processing
class PreliminaryLine {
  String text;
  bool isChordLine;
  bool wasSplit;

  PreliminaryLine({
    required this.text,
    required this.isChordLine,
    this.wasSplit = false,
  });
}

class SongConverter {
  SongConverter();

  String key = "";
  String title = "";

  // getter

  SongConverter createSongConverter() {
    return SongConverter();
  }

  /// Converts plain text with chords and lyrics to a Song object
  Song convertTextToSong(String text, String setKey, String setTitle,
      {List<String> authors = const []}) {
    // Set VARS
    key = setKey;
    title = setTitle;

    // Parse the text into sections, passing the key
    final sections = parseSections(text, key); // Pass key here

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

  /// Interactive version that returns preliminary data for review
  PreliminarySongData convertTextToSongInteractive(String text, String title,
      {List<String> authors = const []}) {
    // Set VARS
    title = title;

    // Do a preliminary parse to get sections
    final preliminarySections = parseTextForReview(text);

    return PreliminarySongData(
      originalText: text,
      sections: preliminarySections,
      title: title,
      authors: authors,
    );
  }

  /// Parses text into preliminary sections for interactive review
  List<PreliminarySection> parseTextForReview(String text) {
    final List<PreliminarySection> sections = [];
    String? currentSectionTitle;
    List<PreliminaryLine> currentSectionLines = [];

    // Split the text into lines and process each line
    final lines = text.split('\n');

    // Regular expression for common section names in all caps followed by optional number
    final unbracketedSectionRegex = RegExp(
      r'^(VERSE|CHORUS|BRIDGE|INTRO|OUTRO|PRE-CHORUS|INSTRUMENTAL)\s*(\d*):?$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if this is a bracketed section header (e.g., [Verse 1])
      final bracketedSectionMatch = RegExp(r'^\[(.*?)\]').firstMatch(line);
      // Check if this is an unbracketed section header (e.g., VERSE 1)
      final unbracketedSectionMatch = unbracketedSectionRegex.firstMatch(line);

      if (bracketedSectionMatch != null || unbracketedSectionMatch != null) {
        // If we were already processing a section, save it
        if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
          sections.add(
            PreliminarySection(
              title: currentSectionTitle,
              lines: currentSectionLines,
            ),
          );
          currentSectionLines = [];
        }

        if (bracketedSectionMatch != null) {
          currentSectionTitle = bracketedSectionMatch.group(1);
        } else {
          // For unbracketed matches, format the title nicely
          final sectionName = unbracketedSectionMatch!.group(1);
          final sectionNumber = unbracketedSectionMatch.group(2)?.trim() ?? '';
          currentSectionTitle = sectionNumber.isEmpty
              ? sectionName
              : '$sectionName $sectionNumber';
        }
      } else if (line.isNotEmpty) {
        // If no section title yet, create a default section
        currentSectionTitle ??= "Untitled Section";

        // Add the line to the current section with a preliminary chord detection
        currentSectionLines.add(
          PreliminaryLine(
            text: line,
            isChordLine: isChordLine(line),
          ),
        );
      }
    }

    // Add the last section
    if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
      sections.add(
        PreliminarySection(
          title: currentSectionTitle,
          lines: currentSectionLines,
        ),
      );
    }

    return sections;
  }

  /// Creates a final Song object from the corrected preliminary data
  Song finalizeSong(PreliminarySongData preliminaryData, String key) {
    // Process the preliminary sections into final song sections
    List<SongSection> finalSections = [];

    for (var prelimSection in preliminaryData.sections) {
      List<String> sectionLines = [];

      // Convert preliminary lines back to raw lines keeping the chord/lyric structure
      for (var line in prelimSection.lines) {
        sectionLines.add(line.text);
      }

      // Process these lines into LineData objects with chords
      finalSections.add(
        SongSection(
          title: prelimSection.title,
          lines: processReviewedLines(prelimSection.lines, key),
        ),
      );
    }

    // Create a hash for the song
    final hash =
        sha256.convert(utf8.encode(preliminaryData.originalText)).toString();

    // Create song header
    final header = SongHeader(
      name: preliminaryData.title,
      key: key,
      authors: preliminaryData.authors,
    );

    // Create the song object
    return Song(
      hash: hash,
      header: header,
      sections: finalSections,
    );
  }

  /// Parses text into SongSection objects
  List<SongSection> parseSections(String text, String key) {
    // Add key parameter
    final List<SongSection> sections = [];
    String? currentSectionTitle;
    List<String> currentSectionLines = [];

    // Split the text into lines and process each line
    final lines = text.split('\n');

    // Regular expression for common section names in all caps followed by optional number
    final unbracketedSectionRegex = RegExp(
      r'^(VERSE|CHORUS|BRIDGE|INTRO|OUTRO|PRE-CHORUS|INSTRUMENTAL)\s*(\d*):?$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if this is a bracketed section header (e.g., [Verse 1])
      final bracketedSectionMatch = RegExp(r'^\[(.*?)\]').firstMatch(line);
      // Check if this is an unbracketed section header (e.g., VERSE 1)
      final unbracketedSectionMatch = unbracketedSectionRegex.firstMatch(line);

      if (bracketedSectionMatch != null || unbracketedSectionMatch != null) {
        // If we were already processing a section, save it
        if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
          sections.add(
            SongSection(
              title: currentSectionTitle,
              lines:
                  processLyricLines(currentSectionLines, key), // Pass key here
            ),
          );
          currentSectionLines = [];
        }

        if (bracketedSectionMatch != null) {
          currentSectionTitle = bracketedSectionMatch.group(1);
        } else {
          // For unbracketed matches, format the title nicely
          final sectionName = unbracketedSectionMatch!.group(1);
          final sectionNumber = unbracketedSectionMatch.group(2)?.trim() ?? '';
          currentSectionTitle = sectionNumber.isEmpty
              ? sectionName
              : '$sectionName $sectionNumber';
        }
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
          lines: processLyricLines(currentSectionLines, key), // Pass key here
        ),
      );
    }

    return sections;
  }

  /// Processes lines in a section to createLineDataobjects with chords
  List<LineData> processLyricLines(List<String> lines, String key) {
    // Add key parameter
    List<LineData> lyricLines = [];

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

        // Extract chords with their positions, passing the key
        final chords =
            extractChords(chordLine, lyricLine, key); // Pass key here

        // CreateLineDataobject
        lyricLines.add(
          LineData(
            lyrics: lyricLine,
            chords: chords,
          ),
        );

        // Skip the lyric line as we've processed it
        i++;
      } else {
        // This is just a lyric line without chords
        lyricLines.add(
          LineData(
            lyrics: lines[i],
            chords: [],
          ),
        );
      }
    }

    return lyricLines;
  }

  /// Takes the lines after they've been organized as chord/lyric pairs
  /// and processes them into LineData objects
  List<LineData> processReviewedLines(List<PreliminaryLine> lines, String key) {
    List<LineData> lyricLines = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].isChordLine &&
          i + 1 < lines.length &&
          !lines[i + 1].isChordLine) {
        // This is a chord line followed by a lyric line
        final chordLine = lines[i].text;
        final lyricLine = lines[i + 1].text;

        // Extract chords with their positions - Already correctly passing key
        final chords = extractChords(chordLine, lyricLine, key);

        // Create LineData object
        lyricLines.add(
          LineData(
            lyrics: lyricLine,
            chords: chords,
          ),
        );

        // Skip the lyric line as we've processed it
        i++;
      } else if (!lines[i].isChordLine) {
        // This is just a lyric line without chords
        lyricLines.add(
          LineData(
            lyrics: lines[i].text,
            chords: [],
          ),
        );
      }
    }

    return lyricLines;
  }

  /// Checks if a line is likely a chord line
  bool isChordLine(String line) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      return false;
    }
    // Split the line into potential chord tokens
    final potentialChords = trimmedLine.split(RegExp(r'\s+'));
    if (potentialChords.isEmpty ||
        (potentialChords.length == 1 && potentialChords[0].isEmpty)) {
      return false;
    }
    for (final token in potentialChords) {
      if (token.isNotEmpty) {
        // Ensure we don't check empty strings if split somehow produces them
        if (!ChordUtils.isPotentialChordToken(token)) {
          return false;
        }
      }
    }
    return true; // All tokens are chords
  }

  /// Extract chords and their positions from a chord line and lyrics line
  List<Chord> extractChords(String chordLine, String lyricLine, String key) {
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
      String nashvilleValue;
      try {
        // Convert chord to Nashville notation
        nashvilleValue = ChordUtils.chordToNashville(chordText, key);
      } catch (e) {
        // Handle invalid chord conversion
        //print('Invalid chord: $chordText, error: $e');
        nashvilleValue = chordText; // Fallback to original chord text
        continue;
      }

      // Add chord
      chords.add(Chord(
        position: chordPosition,
        value: nashvilleValue,
      ));
    }

    return chords;
  }

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

bool sectionsAreIdentical(PreliminarySection s1, PreliminarySection s2) {
  if (s1.lines.length != s2.lines.length) {
    return false;
  }
  for (int i = 0; i < s1.lines.length; i++) {
    if (s1.lines[i].text != s2.lines[i].text ||
        s1.lines[i].isChordLine != s2.lines[i].isChordLine) {
      return false;
    }
  }
  return true;
}

List<PreliminarySection> processDuplicateSections(
    List<PreliminarySection> originalSections) {
  final Map<String, List<int>> sectionsByTitle = {};
  for (int i = 0; i < originalSections.length; i++) {
    sectionsByTitle.putIfAbsent(originalSections[i].title, () => []).add(i);
  }

  final List<PreliminarySection> finalSections = [];
  final Set<int> processedIndices = {};

  for (int i = 0; i < originalSections.length; i++) {
    if (processedIndices.contains(i)) continue;

    final currentSection = originalSections[i];
    final title = currentSection.title;
    final indices = sectionsByTitle[title]!;

    if (indices.length == 1) {
      // Unique title, just add it
      finalSections.add(currentSection);
      processedIndices.add(i);
    } else {
      // Duplicate title found, check content
      final List<PreliminarySection> group =
          indices.map((idx) => originalSections[idx]).toList();
      final List<PreliminarySection> uniqueSectionsInGroup = [];
      final List<int> uniqueOriginalIndices = [];

      for (int k = 0; k < group.length; k++) {
        final currentGroupSection = group[k];
        final originalIndex = indices[k];
        bool foundMatch = false;
        for (final uniqueSection in uniqueSectionsInGroup) {
          if (sectionsAreIdentical(currentGroupSection, uniqueSection)) {
            foundMatch = true;
            break;
          }
        }
        if (!foundMatch) {
          uniqueSectionsInGroup.add(currentGroupSection);
          uniqueOriginalIndices.add(
              originalIndex); // Keep track of the first index for this unique content
        }
      }

      if (uniqueSectionsInGroup.length == 1) {
        // All sections with this title are identical, add the first one
        finalSections.add(currentSection); // Add the one at index i
        processedIndices.addAll(indices); // Mark all as processed
      } else {
        // Different sections with the same title, rename and add all
        int count = 1;
        // Iterate through the original indices to maintain order
        for (final idx in indices) {
          if (processedIndices.contains(idx)) {
            continue;
          } // Should not happen here, but safe check

          final sectionToRename = originalSections[idx];
          // Find which unique section it matches to assign the correct base for renaming if needed
          // (Simpler: just rename based on occurrence order)
          final renamedSection = PreliminarySection(
            title: "${sectionToRename.title} ($count)",
            lines: sectionToRename.lines
                .map((l) => PreliminaryLine(
                    text: l.text,
                    isChordLine: l.isChordLine,
                    wasSplit: l.wasSplit))
                .toList(), // Deep copy lines
          );
          finalSections.add(renamedSection);
          processedIndices.add(idx);
          count++;
        }
      }
    }
  }
  return finalSections;
}
