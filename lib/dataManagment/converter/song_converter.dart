import 'dart:convert';
import 'package:P2pChords/dataManagment/converter/classes.dart';
import 'package:P2pChords/dataManagment/converter/section_management.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:crypto/crypto.dart';

class SongConverter {
  SongConverter();

  String key = "";
  String title = "";

  // MAIN
  PreliminarySongData convertTextToSongInteractive(String text, String title,
      {List<String> authors = const [], String key = ""}) {
    this.title = title;
    this.key = key;

    // GET sections
    final List<SongSection> finalSections = parseSections(text, key);
    final List<PreliminarySection> preliminarySections =
        convertFinalSectionsToPreliminary(finalSections, key);

    return PreliminarySongData(
      originalText: text,
      sections: preliminarySections,
      title: title,
      authors: authors,
      key: key,
    );
  }

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
    final originalLine = lines[i]; // ← Keep original line with spacing
    final trimmedLine = originalLine.trim(); // ← Trim only for checking

    // Check for section headers using trimmed version
    final bracketedSectionMatch = RegExp(r'^\[(.*?)\]').firstMatch(trimmedLine);
    final unbracketedSectionMatch = unbracketedSectionRegex.firstMatch(trimmedLine);

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
    } else if (trimmedLine.isNotEmpty) { // ← Check if trimmed is empty
      currentSectionTitle ??= "Untitled Section";
      currentSectionLines.add(originalLine); // ← Add ORIGINAL line, not trimmed!
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

    for (SongSection section in finalSections) {
      List<PreliminaryLine> preliminaryLines = [];

      for (LineData lineData in section.lines) {
        if (lineData.chords.isNotEmpty) {
          String chordLine = reconstructChordLineFromChords(
              lineData.chords, lineData.lyrics.length, key);

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
    //print(buffer.toString());
    return buffer.toString();
  }

  /// Extract chords using character width mapping approach
  /// This preserves the visual positioning from the raw scraped data
  List<Chord> extractChordsWithCleaning(String originalChordLine,
      String cleanedChordLine, String lyricLine, String key) {
    List<Chord> chords = [];


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

      final certainty = getChordLineCertainty(lines[i]);
      //print('Line: "${lines[i]}" - Certainty: $certainty');
      
      if (certainty > 0.5) {
        String originalChordLine = lines[i];
        String cleanedChordLine = cleanChordLineText(originalChordLine);
        
        // Check if next line is lyrics
        if (i + 1 < lines.length && getChordLineCertainty(lines[i + 1]) < 0.5) {
          // Chord line with lyrics below
          final lyricLine = lines[i + 1];
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
          // Standalone chord line (instrumental section)
          final chords = extractChordsWithCleaning(
              originalChordLine, cleanedChordLine, originalChordLine, key);
          
          
          int maxEndPosition = originalChordLine.length;
          if (chords.isNotEmpty) {
            // Find the rightmost chord and add its display width
            chords.sort((a, b) => b.position.compareTo(a.position)); // Sort descending
            final lastChord = chords.first;
            final lastChordText = ChordUtils.nashvilleToChord(lastChord.value, key);
            maxEndPosition = lastChord.position + lastChordText.length + 5; // +5 for safety
          }
          
          final placeholderLyrics = ' ' * maxEndPosition;

          lyricLines.add(
            LineData(
              lyrics: placeholderLyrics, 
              chords: chords,
            ),
          );
        }
      } else {
        // Just a lyric line without chords
        print('|${lines[i]}|');
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
      if (lines[i].isChordLine) {
        // This is a chord line
        final chordLine = lines[i].text;

        if (i + 1 < lines.length && !lines[i + 1].isChordLine) {
          // It's followed by a lyric line
          final lyricLine = lines[i + 1].text;
          final chords = extractChords(chordLine, lyricLine, key);
          lyricLines.add(
            LineData(
              lyrics: lyricLine,
              chords: chords,
            ),
          );
          i++; // Skip the lyric line
        } else {
          // It's a chord-only line (instrumental)
          final chords = extractChords(chordLine, chordLine, key);
          lyricLines.add(
            LineData(
              lyrics: '', // No lyrics
              chords: chords,
            ),
          );
        }
      } else {
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

  /// Checks if a line is likely a chord line by calculating a certainty score.
  /// Returns a double between 0.0 (definitely not a chord line) and 1.0 (definitely a chord line).
  double getChordLineCertainty(String line) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      return 0.0;
    }

    final allTokens = trimmedLine.split(RegExp(r'\s+'));

    final contentTokens = allTokens.where((token) {
      final cleanToken = token.trim();
      if (cleanToken.isEmpty ||
          RegExp(r'^[|\-/:().]+$').hasMatch(cleanToken)) {
        return false;
      }
      return true;
    }).toList();

    if (contentTokens.isEmpty) {
      return 0.0;
    }

    int chordCount = 0;

    for (final token in contentTokens) {
      if (ChordUtils.isPotentialChordToken(token)) {
        chordCount++;
      } 
    }

    if (chordCount == 0) {
      return 0.0;
    }

    return chordCount / contentTokens.length.toDouble();
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


/// Process duplicate sections with improved UX
Future<List<PreliminarySection>> processDuplicateSectionsInteractive(
  List<PreliminarySection> originalSections, {
  required BuildContext context,
  bool showDialog = true,
}) async {
  // Group all sections
  final groups = groupSections(originalSections);
  
  // Filter to only groups with issues
  final duplicateGroups = groups.where((g) => 
    g.hasDuplicates && !g.hasIdenticalContent
  ).toList();

  // If no duplicates need user input, auto-process
  if (duplicateGroups.isEmpty || !showDialog) {
    return applyResolutions(groups);
  }

  // Show streamlined duplicate resolution dialog
  final resolvedGroups = await showDuplicateResolutionDialog(
    context: context,
    groups: duplicateGroups,
  );

  if (resolvedGroups == null) {
    // User cancelled, return original
    return originalSections;
  }

  // Update resolutions in main groups list
  for (final resolved in resolvedGroups) {
    final index = groups.indexWhere((g) => g.title == resolved.title);
    if (index != -1) {
      groups[index] = resolved;
    }
  }

  return applyResolutions(groups);
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
