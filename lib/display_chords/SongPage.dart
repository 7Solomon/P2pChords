import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'KeySelectPage.dart';

class ChordSheetPage extends StatefulWidget {
  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  Map<String, dynamic>? songData;
  List<Widget> songStructure = [];
  Map<String, Map<String, String>> nashvilleToChordMapping = {};

  int _current_section_1 = 0;
  int _current_section_2 = 1;

  String currentKey = "C";

  void displaySnack(String str) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
  }

  @override
  void initState() {
    super.initState();
    loadMappings();
    loadSongData();
  }

  Future<void> loadSongData() async {
    String jsonString = await rootBundle.loadString('assets/test.json');
    setState(() {
      songData = json.decode(jsonString);
      // Set Song Structure
      currentKey = songData!['header']['key'];
      songStructure = buildSongContent(songData!['data']);
    });
  }

  Future<void> loadMappings() async {
    // Load Nashville to chord mapping
    String jsonString =
        await rootBundle.loadString('assets/nashville_to_chord_by_key.json');
    final dynamic decodedJson = json.decode(jsonString);
    setState(() {
      nashvilleToChordMapping = (decodedJson as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (subKey, subValue) => MapEntry(subKey, subValue as String),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (songData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(songData!['header']['name']),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                '${songData!['header']['name']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Song Data

            Text(
              'Key: ${songData!['header']['key']}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'BPM: ${songData!['header']['bpm']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Rhytmus: ${songData!['header']['time_signature']}'),
            Text('Authoren: ${songData!['header']['authors'].join(', ')}'),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Einstellungen'),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                final selectedKey = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KeySelectionPage()),
                );
                if (selectedKey != null && selectedKey != currentKey) {
                  setState(() {
                    currentKey = selectedKey;
                    songStructure = buildSongContent(songData!['data']);
                  });
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displaySectionContent(),
          ),
        ),
      ),
    );
  }

  List<Widget> displaySectionContent() {
    List<Widget> displayData = [];
    if (_current_section_1 >= 0 && _current_section_1 < songStructure.length) {
      displayData.add(GestureDetector(
        onTap: () {
          setState(() {
            if (_current_section_1 > 0) {
              _current_section_2 = _current_section_1;
              _current_section_1--;
            }
          });
        },
        child: songStructure[_current_section_1],
      ));
    }
    if (_current_section_2 >= 0 && _current_section_2 < songStructure.length) {
      displayData.add(GestureDetector(
        onTap: () {
          setState(() {
            if (_current_section_2 < songStructure.length - 1) {
              _current_section_1 = _current_section_2;
              _current_section_2++;
            }
          });
        },
        child: songStructure[_current_section_2],
      ));
    }

    if (displayData.isEmpty) {
      return [const Text('Something went wrong')];
    }
    return displayData;
  }

  List<Widget> buildSongContent(Map<String, dynamic> data) {
    List<Widget> sectionWidgets = [];

    data.forEach((section, content) {
      List<Widget> oneSection = [];
      // Verse/chorus ansage
      oneSection.add(Text(
        section.toUpperCase(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ));

      oneSection.add(const SizedBox(height: 10));

      // Richtiges Format?
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
        displaySnack(
            'Unexpected content format for section $section: $content');
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

  Map<String, String> parseChords(dynamic chordsData) {
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
}

class LyricsWithChords extends StatelessWidget {
  final String lyrics;
  final Map<String, String> chords;

  LyricsWithChords({required this.lyrics, required this.chords});

  @override
  Widget build(BuildContext context) {
    // Convert string keys to integers
    final Map<int, String> intChords =
        chords.map((key, value) => MapEntry(int.parse(key), value));

    // Calculate the height needed for both chords and lyrics
    final textPainter = TextPainter(
      text: TextSpan(text: lyrics, style: TextStyle(fontSize: 16)),
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
  // #### Nicht funtional
  // Functioniert noch nicht richtig sollte eigentlich den Abstand zwischen den Chords regeln, kann vielleivht mit spaces geregelt werde

  @override
  void paint(Canvas canvas, Size size) {
    final lyricPainter = TextPainter(
      text: TextSpan(text: lyrics, style: lyricStyle),
      textDirection: TextDirection.ltr,
    );
    lyricPainter.layout(maxWidth: size.width);

    final chordPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    chords.forEach((index, chord) {
      final offset = lyricPainter.getOffsetForCaret(
        TextPosition(offset: index),
        Rect.zero,
      );

      chordPainter.text = TextSpan(text: chord, style: chordStyle);
      chordPainter.layout();
      chordPainter.paint(canvas, Offset(offset.dx, 0));

      lyricPainter.paint(canvas, Offset(0, chordPainter.height + 5));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
