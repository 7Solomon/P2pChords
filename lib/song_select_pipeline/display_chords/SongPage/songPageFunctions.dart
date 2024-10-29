import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

List<Widget> displaySectionContent({
  required Map<String, List<Widget>> songStructure,
  required List<Map<String, String>> groupSongs,
  required String currentSongHash,
  required List<int> currentSections,
  //required Function(List<int>) updateSections,
  required Function() onEndReached,
  required Function() onStartReached,
}) {
  List<Widget> displayData = [];
  List<Widget> sectionWidgets = songStructure[currentSongHash] ?? [];

  // Add all requested sections
  for (int sectionIndex in currentSections) {
    if (sectionIndex >= 0 && sectionIndex < sectionWidgets.length) {
      displayData.add(sectionWidgets[sectionIndex]);
    }
  }

  if (displayData.isEmpty) {
    return [const Text('Keine Songdaten verfügbar')];
  }
  return displayData;
}

// New widget to handle screen taps
class SongDisplayScreen extends StatelessWidget {
  final Map<String, List<Widget>> songStructure;
  final List<Map<String, String>> groupSongs;
  final String currentSongHash;
  final List<int> currentSections;
  final Function(String, List<int>, int) updateSections;
  final Function() onEndReached;
  final Function() onStartReached;

  const SongDisplayScreen({
    Key? key,
    required this.songStructure,
    required this.groupSongs,
    required this.currentSongHash,
    required this.currentSections,
    required this.updateSections,
    required this.onEndReached,
    required this.onStartReached,
  }) : super(key: key);

  void _handleTap(BuildContext context, Offset tapPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final double height = box.size.height;
    final bool isTopHalf = tapPosition.dy < height / 2;

    final List<Widget> sectionWidgets = songStructure[currentSongHash] ?? [];

    if (isTopHalf) {
      // Move sections down
      List<int> newSections = currentSections.map((section) {
        if (section > 0) {
          return section - 1;
        } else {
          onEndReached();
          return section;
        }
      }).toList();

      if (!listEquals(newSections, currentSections)) {
        updateSections(currentSongHash, newSections, 2); // das hier auch
      }
    } else {
      // Move sections up
      List<int> newSections = currentSections.map((section) {
        if (section < sectionWidgets.length - 1) {
          return section + 1;
        } else {
          onStartReached();
          return section;
        }
      }).toList();

      if (!listEquals(newSections, currentSections)) {
        updateSections(currentSongHash, newSections,
            2); // maybe muss anders geregelt werden
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Ensures taps are detected everywhere
      onTapDown: (TapDownDetails details) {
        _handleTap(context, details.localPosition);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displaySectionContent(
          songStructure: songStructure,
          groupSongs: groupSongs,
          currentSongHash: currentSongHash,
          currentSections: currentSections,
          //updateSections: updateSections,
          onEndReached: onEndReached,
          onStartReached: onStartReached,
        ),
      ),
    );
  }
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
