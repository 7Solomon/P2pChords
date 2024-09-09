import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

List<Widget> displaySectionContent({
  required Map<String, List<Widget>> songStructure,
  required List<Map<String, String>> groupSongs,
  required String currentSongHash,
  required int currentSection1,
  required int currentSection2,
  required Function(int, int) updateSections,
  required Function() onEndReached, // Add callback for end reach
  required Function() onStartReachedd,
}) {
  List<Widget> displayData = [];
  List<Widget> sectionWidgets = songStructure[currentSongHash] ?? [];

  // Handle the first section
  if (currentSection1 >= 0 && currentSection1 < sectionWidgets.length) {
    displayData.add(GestureDetector(
      onTap: () {
        if (currentSection1 > 0) {
          updateSections(currentSection1 - 1, currentSection1);
        } else {
          // Call onEndReached if needed
          onStartReachedd();
        }
      },
      child: sectionWidgets[currentSection1],
    ));
  }

  // Handle the second section
  if (currentSection2 >= 0 && currentSection2 < sectionWidgets.length) {
    displayData.add(GestureDetector(
      onTap: () {
        if (currentSection2 < sectionWidgets.length - 1) {
          updateSections(currentSection2, currentSection2 + 1);
        } else {
          // Call onEndReached if needed
          onEndReached();
        }
      },
      child: sectionWidgets[currentSection2],
    ));
  }

  if (displayData.isEmpty) {
    return [const Text('Something went wrong')];
  }
  return displayData;
  //return [const Text('ALl good')];
}

List<Widget> buildSongContent(
  Map<String, dynamic> data,
  Function displaySnack,
  Function parseChords,
) {
  List<Widget> sectionWidgets = [];

  data.forEach((section, content) {
    List<Widget> oneSection = [];
    // Verse/chorus label
    oneSection.add(Text(
      section.toUpperCase(),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ));

    oneSection.add(const SizedBox(height: 10));

    if (content is List<dynamic>) {
      for (var lineData in content) {
        if (lineData is Map<String, dynamic>) {
          oneSection.add(LyricsWithChords(
            lyrics: lineData['lyrics'] ?? '',
            chords: parseChords(lineData['chords']),
          ));
        } else {
          displaySnack('Unexpected line data format: $lineData');
        }
      }
    } else {
      displaySnack('Unexpected content format for section $section: $content');
    }
    oneSection.add(const SizedBox(height: 20));

    sectionWidgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: oneSection,
      ),
    );
  });
  return sectionWidgets;
}

Map<String, String> parseChords(
  dynamic chordsData,
  Map<String, Map<String, String>> nashvilleToChordMapping,
  String currentKey,
  Function displaySnack,
) {
  Map<String, String> parsedChords = {};

  if (chordsData is Map<String, dynamic>) {
    if (!nashvilleToChordMapping.containsKey(currentKey)) {
      displaySnack('Unknown key: $currentKey');
      return parsedChords;
    }

    Map<String, String> keyMapping = nashvilleToChordMapping[currentKey]!;

    chordsData.forEach((key, value) {
      int? position = int.tryParse(key);
      if (position != null && value is String) {
        String chord = value;
        String? baseChord;

        // Handle complex chords like 5sus/7 or -6/7
        if (chord.contains('/')) {
          List<String> parts = chord.split('/');
          if (parts.length == 2) {
            String basePart = parts[0]; // e.g., "5sus" or "-6"
            String bassPart = parts[1]; // e.g., "7"

            // Resolve the base and bass part of slash chord
            baseChord = resolveComplexChord(basePart, keyMapping, displaySnack);
            String? bassChordResolved = keyMapping[bassPart];

            if (baseChord != null && bassChordResolved != null) {
              baseChord = "$baseChord/$bassChordResolved";
            } else {
              displaySnack('Unknown Nashville numbers in slash chord: $chord');
              return;
            }
          }
        } else {
          // Handle regular or complex chords (e.g., "5sus", "-6", "-3")
          baseChord = resolveComplexChord(chord, keyMapping, displaySnack);
        }

        if (baseChord != null) {
          parsedChords[position.toString()] = baseChord;
        }
      } else {
        displaySnack('Invalid chord data: key=$key, value=$value');
      }
    });
  } else {
    displaySnack('Unexpected chords data format: $chordsData');
  }

  return parsedChords;
}

// Helper function to resolve complex chords like "5sus", "-6", "-3"
String? resolveComplexChord(
  String chord,
  Map<String, String> keyMapping,
  Function displaySnack,
) {
  String baseChord = chord;
  String? baseChordResolved;

  // Handle minor chords as negative numbers (e.g., "-2", "-6")
  if (chord.startsWith('-')) {
    String minorPart = chord.substring(1); // Remove the "-" sign, e.g., "6"
    baseChordResolved = keyMapping[minorPart];
    if (baseChordResolved != null) {
      baseChordResolved += "m"; // Add "m" for the minor chord, e.g., "Am"
    }
  }
  // Handle suspended chords (e.g., "5sus")
  else if (chord.endsWith('sus')) {
    String suspendedPart =
        chord.substring(0, chord.length - 3); // Remove "sus", e.g., "5"
    baseChordResolved = keyMapping[suspendedPart];
    if (baseChordResolved != null) {
      baseChordResolved += "sus"; // Append "sus", e.g., "Gsus"
    }
  }
  // Handle seventh chords (e.g., "5maj7", "5sus7")
  else if (chord.contains('7')) {
    String basePart =
        chord.replaceAll(RegExp(r'[^\d]'), ''); // Get the base number
    baseChordResolved = keyMapping[basePart];
    if (baseChordResolved != null) {
      baseChordResolved +=
          chord.substring(basePart.length); // Append "maj7" or "sus7"
    }
  }
  // Handle augmented/diminished chords (e.g., "5aug", "7dim")
  else if (chord.endsWith('aug') || chord.endsWith('dim')) {
    String basePart =
        chord.substring(0, chord.length - 3); // Remove "aug" or "dim"
    baseChordResolved = keyMapping[basePart];
    if (baseChordResolved != null) {
      baseChordResolved +=
          chord.substring(basePart.length); // Append "aug" or "dim"
    }
  }
  // Handle simple major chords (e.g., "1", "5")
  else {
    baseChordResolved = keyMapping[chord];
  }

  if (baseChordResolved == null) {
    displaySnack('Unknown Nashville number: $chord');
  }

  return baseChordResolved;
}
