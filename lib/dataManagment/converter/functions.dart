import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/converter/components/section_duplicate_dialog.dart';
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

  /// Parses text into final SongSection objects for direct conversion
  List<SongSection> parseSections(String text, String key) {
    final List<SongSection> sections = [];
    String? currentSectionTitle;
    List<String> currentSectionLines = [];

    final lines = text.split('\n');
    final unbracketedSectionRegex = RegExp(
      r'^(VERSE|CHORUS|BRIDGE|INTRO|OUTRO|PRE-CHORUS|INSTRUMENTAL)\s*(\d*):?$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check for section headers
      final bracketedSectionMatch = RegExp(r'^\[(.*?)\]').firstMatch(line);
      final unbracketedSectionMatch = unbracketedSectionRegex.firstMatch(line);

      if (bracketedSectionMatch != null || unbracketedSectionMatch != null) {
        // Save previous section
        if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
          sections.add(
            SongSection(
              title: currentSectionTitle,
              lines: processLyricLines(currentSectionLines, key),
            ),
          );
          currentSectionLines = [];
        }

        // Set new section title
        if (bracketedSectionMatch != null) {
          currentSectionTitle = bracketedSectionMatch.group(1);
        } else {
          final sectionName = unbracketedSectionMatch!.group(1);
          final sectionNumber = unbracketedSectionMatch.group(2)?.trim() ?? '';
          currentSectionTitle = sectionNumber.isEmpty
              ? sectionName
              : '$sectionName $sectionNumber';
        }
      } else if (line.isNotEmpty) {
        currentSectionTitle ??= "Untitled Section";

        // Don't clean chord lines here - preserve original spacing for position extraction
        currentSectionLines.add(line);
      }
    }

    // Add the last section
    if (currentSectionTitle != null && currentSectionLines.isNotEmpty) {
      sections.add(
        SongSection(
          title: currentSectionTitle,
          lines: processLyricLines(currentSectionLines, key),
        ),
      );
    }

    return sections;
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
  /// Now performs real-time conversion with proper chord positioning
  PreliminarySongData convertTextToSongInteractive(String text, String title,
      {List<String> authors = const [], String key = ""}) {
    // Set VARS
    this.title = title;
    this.key = key;

    //print("REAL-TIME CONVERSION: Starting with key '$key'");

    // Parse the text into final sections with proper chord positioning
    final finalSections = parseSections(text, key);

    // Convert final sections back to preliminary format for editing
    final preliminarySections =
        convertFinalSectionsToPreliminary(finalSections, key);

    return PreliminarySongData(
      originalText: text,
      sections: preliminarySections,
      title: title,
      authors: authors,
      key: key,
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
      //print('Section: $currentSectionTitle');
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

        // Detect if this is a chord line
        bool isChordLineDetected = isChordLine(line);

        // Preserve original text including spacing for chord lines
        // Add the line to the current section with original text
        currentSectionLines.add(
          PreliminaryLine(
            text: line,  // Use original line, not cleaned
            isChordLine: isChordLineDetected,
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

  /// Converts final SongSection objects back to PreliminarySection format
  /// This allows the interactive editor to work with properly positioned chords
  List<PreliminarySection> convertFinalSectionsToPreliminary(
      List<SongSection> finalSections, String key) {
    List<PreliminarySection> preliminarySections = [];

    for (var section in finalSections) {
      List<PreliminaryLine> preliminaryLines = [];

      for (var lineData in section.lines) {
        if (lineData.chords.isNotEmpty) {
          // Reconstruct chord line from positioned chords
          String chordLine = reconstructChordLineFromChords(
              lineData.chords, lineData.lyrics.length, key);

          // Add chord line
          preliminaryLines.add(PreliminaryLine(
            text: chordLine,
            isChordLine: true,
            wasSplit: false,
          ));
        }

        // Add lyric line
        preliminaryLines.add(PreliminaryLine(
          text: lineData.lyrics,
          isChordLine: false,
          wasSplit: lineData.chords.isNotEmpty
              ? false
              : false, // Only wasSplit if part of a pair
        ));
      }

      preliminarySections.add(PreliminarySection(
        title: section.title,
        lines: preliminaryLines,
      ));
    }

    return preliminarySections;
  }

  /// Reconstructs a chord line text from positioned chord objects
  String reconstructChordLineFromChords(
      List<Chord> chords, int lyricLength, String key) {
    if (chords.isEmpty) return "";

    // Sort chords by position
    chords.sort((a, b) => a.position.compareTo(b.position));

    StringBuffer buffer = StringBuffer();
    int currentPos = 0;

    for (var chord in chords) {
      // Add spaces to reach the chord position
      if (chord.position > currentPos) {
        buffer.write(' ' * (chord.position - currentPos));
      }

      // Convert Nashville back to standard chord notation for display
      String standardChord = ChordUtils.nashvilleToChord(chord.value, key);
      buffer.write(standardChord);
      currentPos = chord.position + standardChord.length;
    }

    //print("RECONSTRUCTED CHORD LINE: '${buffer.toString()}'");
    return buffer.toString();
  }

  /// Extract chords using character width mapping approach
  /// This preserves the visual positioning from the raw scraped data
  List<Chord> extractChordsWithCleaning(String originalChordLine,
      String cleanedChordLine, String lyricLine, String key) {
    List<Chord> chords = [];

    // DEBUG: Print the lines for comparison
    //print("ORIGINAL: '$originalChordLine'");
    //print("CLEANED:  '$cleanedChordLine'");
    //print("LYRICS:   '$lyricLine'");

    // Use regex to find chord positions in the ORIGINAL line (preserving spacing)
    final chordMatches = RegExp(r'(\S+)').allMatches(originalChordLine);
    //print(
    //    "CHORD MATCHES: ${chordMatches.map((m) => '${m.group(0)}@${m.start}').join(', ')}");

    for (var match in chordMatches) {
      final chordText = match.group(0)!;
      final chordLinePosition = match.start; // Position in chord line

      // Map chord line position to lyric line position using character width logic
      final mappedPosition = _mapChordPositionToLyrics(
          chordLinePosition, originalChordLine, lyricLine);

      //print(
      //    "MAPPING: Chord '$chordText' from chord-pos $chordLinePosition to lyric-pos $mappedPosition");

      try {
        // Validate that this is actually a chord
        if (!ChordUtils.isPotentialChordToken(chordText)) {
          //print("SKIPPING: '$chordText' - not a valid chord token");
          continue;
        }

        // Convert chord to Nashville notation
        String nashvilleValue = ChordUtils.chordToNashville(chordText, key);

        // Add chord with mapped position
        chords.add(Chord(position: mappedPosition, value: nashvilleValue));
        //print("ADDED: Chord $chordText at mapped position $mappedPosition");
      } catch (e) {
        //print("ERROR converting chord '$chordText': $e");
        continue; // Skip invalid chords
      }
    }

    //print(
    //    "FINAL CHORDS: ${chords.map((c) => '${c.value}@${c.position}').join(', ')}");
    return chords;
  }

  /// Maps a position in the chord line to the corresponding position in the lyric line
  /// This preserves the visual alignment as intended in the original chord chart
  int _mapChordPositionToLyrics(
      int chordPosition, String chordLine, String lyricLine) {
    // The chord position represents the intended visual alignment
    // We should preserve this position directly, only clamping to prevent overflow
    final mappedPosition = chordPosition.clamp(0, lyricLine.length);

    //print(
    //    "CHAR MAPPING: chord-pos $chordPosition -> lyric-pos $mappedPosition (chord-len: ${chordLine.length}, lyric-len: ${lyricLine.length})");

    return mappedPosition;
  }

  /// Alternative method: Calculate positions from cleaned line instead
  List<Chord> extractChordsFromCleanedLine(
      String cleanedChordLine, String lyricLine, String key) {
    List<Chord> chords = [];

    final chordMatches = RegExp(r'(\S+)').allMatches(cleanedChordLine);

    for (var match in chordMatches) {
      final chordText = match.group(0)!;
      final position = match.start; // Position in cleaned line

      try {
        // Validate chord token
        if (!ChordUtils.isPotentialChordToken(chordText)) continue;

        String nashvilleValue = ChordUtils.chordToNashville(chordText, key);

        // Clamp position to lyric length
        final clampedPosition = position.clamp(0, lyricLine.length);

        chords.add(Chord(
          position: clampedPosition,
          value: nashvilleValue,
        ));

        //print("CLEAN METHOD - Chord: $chordText at position $clampedPosition");
      } catch (e) {
        //print("ERROR converting chord '$chordText': $e");
        continue;
      }
    }

    return chords;
  }

  /// Processes lines in a section to create LineData objects with chords
  List<LineData> processLyricLines(List<String> lines, String key) {
    List<LineData> lyricLines = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      if (isChordLine(lines[i]) &&
          i + 1 < lines.length &&
          !isChordLine(lines[i + 1])) {
        // This is a chord line and the next is a lyric line
        String originalChordLine = lines[i];
        String cleanedChordLine = cleanChordLineText(originalChordLine);
        final lyricLine = lines[i + 1];

        // Extract chords using both original and cleaned versions
        final chords = extractChordsWithCleaning(
            originalChordLine, cleanedChordLine, lyricLine, key);

        lyricLines.add(
          LineData(
            lyrics: lyricLine,
            chords: chords,
          ),
        );

        i++; // Skip the lyric line
      } else {
        // Just a lyric line without chords
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

    // Split the line into potential tokens
    final allTokens = trimmedLine.split(RegExp(r'\s+'));

    // Filter out special characters and keep only potential chord tokens
    final chordTokens = allTokens.where((token) {
      final cleanToken = token.trim();
      // Skip empty tokens and common special characters used in chord charts
      if (cleanToken.isEmpty ||
          cleanToken == '|' ||
          cleanToken == '||' ||
          cleanToken == '/' ||
          cleanToken == '-' ||
          cleanToken == ':' ||
          cleanToken == '.' ||
          cleanToken == '(' ||
          cleanToken == ')' ||
          RegExp(r'^[|\-/:().]+$').hasMatch(cleanToken)) {
        return false;
      }
      return true;
    }).toList();

    // If no valid tokens after filtering, it's not a chord line
    if (chordTokens.isEmpty) {
      return false;
    }

    // Check if all remaining tokens are potential chords
    for (final token in chordTokens) {
      if (!ChordUtils.isPotentialChordToken(token)) {
        return false;
      }
    }

    return true; // All non-special tokens are chords
  }

  /// Enhanced method to extract only chord tokens from a line, filtering out special characters
  List<String> extractChordTokensFromLine(String line) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      return [];
    }

    // Split the line into tokens
    final allTokens = trimmedLine.split(RegExp(r'\s+'));

    // Filter and return only valid chord tokens
    return allTokens.where((token) {
      final cleanToken = token.trim();

      // Skip special characters commonly used in chord charts
      if (cleanToken.isEmpty ||
          cleanToken == '|' ||
          cleanToken == '||' ||
          cleanToken == '/' ||
          cleanToken == '-' ||
          cleanToken == ':' ||
          cleanToken == '.' ||
          cleanToken == '(' ||
          cleanToken == ')' ||
          RegExp(r'^[|\-/:().]+$').hasMatch(cleanToken)) {
        return false;
      }

      // Only return if it's a potential chord
      return ChordUtils.isPotentialChordToken(cleanToken);
    }).toList();
  }

  List<Chord> extractChords(String chordLine, String lyricLine, String key) {
    String cleanedChordLine = cleanChordLineText(chordLine);

    return extractChordsWithCleaning(
        chordLine, cleanedChordLine, lyricLine, key);
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

/// Processes duplicate sections while preserving order and showing interactive dialogs
///
/// Features:
/// - Preserves the original order of sections in the song
/// - Shows a mobile-friendly popup dialog when duplicate section titles are found with different content
/// - Highlights differences between sections in red for easy identification
/// - Allows users to choose:
///   - Keep first version only
///   - Keep second version only
///   - Keep both versions (automatically numbered)
/// - Falls back to automatic numbering if dialog interaction fails
///
/// Usage:
/// ```dart
/// final processedSections = await processDuplicateSectionsInteractive(
///   originalSections,
///   context: context,
///   showDialog: true, // Set to false to skip dialogs and use automatic processing
/// );
/// ```
Future<List<PreliminarySection>> processDuplicateSectionsInteractive(
  List<PreliminarySection> originalSections, {
  required BuildContext context,
  bool showDialog = true,
}) async {
  final List<PreliminarySection> finalSections = [];
  final Map<String, List<int>> seenSectionIndices = {};
  final Map<String, int> titleCounters = {};

  for (int i = 0; i < originalSections.length; i++) {
    final currentSection = originalSections[i];
    final title = currentSection.title;

    seenSectionIndices.putIfAbsent(title, () => []);
    titleCounters.putIfAbsent(title, () => 0);

    // Check if we've seen an identical section with this title
    bool foundIdentical = false;
    for (final seenIndex in seenSectionIndices[title]!) {
      if (sectionsAreIdentical(currentSection, originalSections[seenIndex])) {
        foundIdentical = true;
        break;
      }
    }

    if (foundIdentical) {
      continue; // Skip identical sections
    }

    // Check if we've seen a different section with the same title
    bool foundDifferentWithSameTitle = false;
    int? conflictingIndex;
    for (final seenIndex in seenSectionIndices[title]!) {
      if (!sectionsAreIdentical(currentSection, originalSections[seenIndex])) {
        foundDifferentWithSameTitle = true;
        conflictingIndex = seenIndex;
        break;
      }
    }

    if (foundDifferentWithSameTitle && showDialog && conflictingIndex != null) {
      // Show dialog to user for conflict resolution
      final action = await _showSectionConflictDialog(
        context: context,
        firstSection: originalSections[conflictingIndex],
        secondSection: currentSection,
        sectionTitle: title,
      );

      switch (action) {
        case SectionDuplicateAction.keepFirst:
          continue;
        case SectionDuplicateAction.keepSecond:
          _replaceExistingSection(finalSections, title, currentSection);
          seenSectionIndices[title]!.add(i);
          continue;
        case SectionDuplicateAction.keepBoth:
          break;
        case SectionDuplicateAction.cancel:
        default:
          break;
      }
    }

    // Add the section (either new or as part of keep both)
    seenSectionIndices[title]!.add(i);
    titleCounters[title] = titleCounters[title]! + 1;

    if (seenSectionIndices[title]!.length == 1) {
      // First section with this title
      bool willHaveDuplicates =
          _willHaveDuplicates(originalSections, i, title, currentSection);

      if (willHaveDuplicates || foundDifferentWithSameTitle) {
        // Add with number (1)
        final numberedSection = PreliminarySection(
          title: "$title (${titleCounters[title]!})",
          lines: _copyLines(currentSection.lines),
        );
        finalSections.add(numberedSection);
      } else {
        // No duplicates coming, add without number
        finalSections.add(currentSection);
      }
    } else {
      // This is a duplicate - always add with number
      final renamedSection = PreliminarySection(
        title: "$title (${titleCounters[title]!})",
        lines: _copyLines(currentSection.lines),
      );
      finalSections.add(renamedSection);

      // If this is the first duplicate (counter = 2), go back and rename the original
      if (titleCounters[title]! == 2) {
        _renumberFirstSection(finalSections, title);
      }
    }
  }

  return finalSections;
}

/// Non-interactive version that preserves the original behavior
List<PreliminarySection> processDuplicateSections(
    List<PreliminarySection> originalSections) {
  final List<PreliminarySection> finalSections = [];
  final Map<String, List<PreliminarySection>> seenSectionsByTitle = {};
  final Map<String, int> titleCounters = {};

  for (int i = 0; i < originalSections.length; i++) {
    final currentSection = originalSections[i];
    final title = currentSection.title;

    seenSectionsByTitle.putIfAbsent(title, () => []);
    titleCounters.putIfAbsent(title, () => 0);

    bool foundIdentical = false;
    for (final seenSection in seenSectionsByTitle[title]!) {
      if (sectionsAreIdentical(currentSection, seenSection)) {
        foundIdentical = true;
        break;
      }
    }

    if (foundIdentical) {
      continue;
    }

    seenSectionsByTitle[title]!.add(currentSection);
    titleCounters[title] = titleCounters[title]! + 1;

    if (seenSectionsByTitle[title]!.length == 1) {
      bool willHaveDuplicates =
          _willHaveDuplicates(originalSections, i, title, currentSection);

      if (willHaveDuplicates) {
        final numberedSection = PreliminarySection(
          title: "$title (${titleCounters[title]!})",
          lines: _copyLines(currentSection.lines),
        );
        finalSections.add(numberedSection);
      } else {
        finalSections.add(currentSection);
      }
    } else {
      final renamedSection = PreliminarySection(
        title: "$title (${titleCounters[title]!})",
        lines: _copyLines(currentSection.lines),
      );
      finalSections.add(renamedSection);

      if (titleCounters[title]! == 2) {
        _renumberFirstSection(finalSections, title);
      }
    }
  }

  return finalSections;
}

// Helper functions
bool _willHaveDuplicates(List<PreliminarySection> originalSections,
    int currentIndex, String title, PreliminarySection currentSection) {
  for (int j = currentIndex + 1; j < originalSections.length; j++) {
    if (originalSections[j].title == title &&
        !sectionsAreIdentical(currentSection, originalSections[j])) {
      return true;
    }
  }
  return false;
}

List<PreliminaryLine> _copyLines(List<PreliminaryLine> lines) {
  return lines
      .map((l) => PreliminaryLine(
          text: l.text, isChordLine: l.isChordLine, wasSplit: l.wasSplit))
      .toList();
}

void _replaceExistingSection(List<PreliminarySection> finalSections,
    String title, PreliminarySection newSection) {
  for (int j = 0; j < finalSections.length; j++) {
    if (finalSections[j].title == title ||
        finalSections[j].title.startsWith("$title (")) {
      finalSections[j] = newSection;
      break;
    }
  }
}

void _renumberFirstSection(
    List<PreliminarySection> finalSections, String title) {
  for (int j = 0; j < finalSections.length - 1; j++) {
    if (finalSections[j].title == title) {
      finalSections[j] = PreliminarySection(
        title: "$title (1)",
        lines: finalSections[j].lines,
      );
      break;
    }
  }
}

Future<SectionDuplicateAction?> _showSectionConflictDialog({
  required BuildContext context,
  required PreliminarySection firstSection,
  required PreliminarySection secondSection,
  required String sectionTitle,
}) async {
  try {
    return await showSectionDuplicateDialog(
      context: context,
      firstSection: firstSection,
      secondSection: secondSection,
      sectionTitle: sectionTitle,
    );
  } catch (e) {
    // Fallback to automatic behavior if dialog not available
    return SectionDuplicateAction.keepBoth;
  }
}

String cleanChordLineText(String text) {
  return text
      // Remove single and double pipes with surrounding whitespace
      .replaceAll(RegExp(r'\s*\|\s*'), ' ')
      .replaceAll(RegExp(r'\s*\|\|\s*'), ' ')

      // Remove multiple dashes (keep single dashes as they might be in chord names like "sus4-")
      .replaceAll(RegExp(r'\s*-{2,}\s*'), ' ')

      // Remove multiple colons
      .replaceAll(RegExp(r'\s*:{2,}\s*'), ' ')

      // Remove isolated forward slashes (not part of slash chords like C/G)
      .replaceAll(RegExp(r'\s+/\s+'), ' ')

      // Remove parentheses that are not part of chord notation
      .replaceAll(RegExp(r'\s*\(\s*\)\s*'), ' ')

      // Remove dots that are standalone
      .replaceAll(RegExp(r'\s+\.\s+'), ' ')

      // Normalize multiple spaces to single space
      .replaceAll(RegExp(r'\s+'), ' ')

      // Clean up leading/trailing whitespace
      .trim();
}
