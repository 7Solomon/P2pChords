import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChordSheetPage extends StatefulWidget {
  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  Map<String, dynamic>? songData;
  List<Widget> songStructure = [];

  int _current_section_1 = 0;
  int _current_section_2 = 1;

  void displaySnack(String str) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
  }

  @override
  void initState() {
    super.initState();
    loadSongData();
  }

  Future<void> loadSongData() async {
    String jsonString = await rootBundle.loadString('assets/test.json');
    setState(() {
      songData = json.decode(jsonString);
      // Set Song Structure
      songStructure = buildSongContent(songData!['data']);
      for (var _ in songStructure) {
        print(_);
      }
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Song Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Song Data
            Text(
              '${songData!['header']['name']}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Key: ${songData!['header']['key']}'),
            Text('BPM: ${songData!['header']['bpm']}'),
            Text('Time: ${songData!['header']['time_signature']}'),
            Text('Authors: ${songData!['header']['authors'].join(', ')}'),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Handle the settings action here
                Navigator.pop(context); // Close the drawer
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
            children: [...displaySectionContent()],
          ),
        ),
      ),
    );
  }

  List<Widget> displaySectionContent() {
    List<Widget> displayData = [];
    if (_current_section_1 < songStructure.length) {
      displayData.add(songStructure[_current_section_1]);
    }
    if (_current_section_2 < songStructure.length) {
      displayData.add(songStructure[_current_section_2]);
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
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ));

      oneSection.add(SizedBox(height: 10));

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
        GestureDetector(
          onTap: () {
            // Handle the press event, you can specify the action here
            print('Section $section pressed');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: oneSection,
          ),
        ),
      );
    });
    return sectionWidgets;
  }

  Map<String, String> parseChords(dynamic chordsData) {
    Map<String, String> parsedChords = {};
    if (chordsData is Map<String, dynamic>) {
      chordsData.forEach((key, value) {
        int? position = int.tryParse(key);
        if (position != null && value is String) {
          parsedChords[position.toString()] = value;
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

    // Manages that the Chord and Lyrics are over eachother
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(
          painter: ChordPainter(lyrics: lyrics, chords: intChords),
          child: Container(height: 30),
        ),
        Text(lyrics),
        SizedBox(height: 10),
      ],
    );
  }
}

class ChordPainter extends CustomPainter {
  final String lyrics;
  final Map<int, String> chords;

  ChordPainter({required this.lyrics, required this.chords});
  // #### Nicht funtional
  // Functioniert noch nicht richtig sollte eigentlich den Abstand zwischen den Chords regeln, kann vielleivht mit spaces geregelt werde
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: lyrics, style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    chords.forEach((index, chord) {
      final offset = textPainter.getOffsetForCaret(
        TextPosition(offset: index),
        Rect.zero,
      );
      textPainter.text = TextSpan(
          text: chord, style: TextStyle(fontSize: 14, color: Colors.blue));
      textPainter.layout();
      textPainter.paint(canvas, Offset(offset.dx, 0));
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
