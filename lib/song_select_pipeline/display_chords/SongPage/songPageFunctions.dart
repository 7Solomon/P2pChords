import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';
import 'package:flutter/material.dart';

List<Widget> displaySectionContent({
  required List<Widget> songStructure,
  required int currentSection1,
  required int currentSection2,
  required Function(int, int) updateSections,
}) {
  List<Widget> displayData = [];
  if (currentSection1 >= 0 && currentSection1 < songStructure.length) {
    displayData.add(GestureDetector(
      onTap: () {
        if (currentSection1 > 0) {
          updateSections(currentSection1 - 1, currentSection1);
        }
      },
      child: songStructure[currentSection1],
    ));
  }
  if (currentSection2 >= 0 && currentSection2 < songStructure.length) {
    displayData.add(GestureDetector(
      onTap: () {
        if (currentSection2 < songStructure.length - 1) {
          updateSections(currentSection2, currentSection2 + 1);
        }
      },
      child: songStructure[currentSection2],
    ));
  }

  if (displayData.isEmpty) {
    return [const Text('Something went wrong')];
  }
  return displayData;
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
        String? chord = keyMapping[value];
        if (chord != null) {
          parsedChords[position.toString()] = chord;
        } else {
          displaySnack('Unknown Nashville number: $value');
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
