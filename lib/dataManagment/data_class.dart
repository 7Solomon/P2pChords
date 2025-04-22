import 'dart:convert';

import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/chords_parsing.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/material.dart';

/// Utility class for chord operations and Nashville number system conversions
class ChordUtils {
  static Map<String, Map<String, String>>? _nashvilleMappings;
  static bool _initialized = false;

  /// Initialize the chord mappings from assets
  static Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/nashville_to_chord_by_key.json');
    _nashvilleMappings = Map<String, Map<String, String>>.from(json
        .decode(jsonString)
        .map((key, value) => MapEntry(key, Map<String, String>.from(value))));
    _initialized = true;
  }

  /// Check if mappings are initialized
  static bool get isInitialized => _initialized;

  /// Get all supported keys
  static List<String> get availableKeys =>
      _checkInitialized() ? _nashvilleMappings!.keys.toList() : [];

  static String nashvilleToChord(String nashvilleNumber, String key) {
    _checkInitialized();

    if (nashvilleNumber == "N.C." || key.isEmpty) {
      return nashvilleNumber; // Return as-is for "No Chord" or if no key provided
    }

    // Handle slash chords in Nashville notation (e.g. "4/1")
    if (nashvilleNumber.contains('/')) {
      List<String> parts = nashvilleNumber.split('/');
      if (parts.length == 2) {
        String baseNashville = parts[0].trim();
        String bassNashville = parts[1].trim();

        // Convert each part separately
        String baseChord = nashvilleToChord(baseNashville, key);

        // For the bass part, we need to find the note corresponding to the number
        String bassNote = "";
        if (RegExp(r'^\d+$').hasMatch(bassNashville)) {
          // If it's just a number, convert it to the root note
          bassNote = _nashvilleMappings![key]![bassNashville] ?? bassNashville;
        } else {
          // If it has modifiers, convert the whole thing
          bassNote = nashvilleToChord(bassNashville, key);
        }

        return "$baseChord/$bassNote";
      }
    }

    // Extract number and modifiers
    final nashvilleRegex = RegExp(r'^(\d+)(.*)$');
    final match = nashvilleRegex.firstMatch(nashvilleNumber);

    if (match == null) {
      // If not matching our expected format, use the existing robust parsing
      return _fallbackNashvilleToChord(nashvilleNumber, key);
    }

    final number = match.group(1)!;
    String modifiers = match.group(2) ?? '';

    // Get the corresponding note from mappings
    final note = _nashvilleMappings![key]![number];
    if (note == null) {
      return _fallbackNashvilleToChord(nashvilleNumber, key);
    }

    // Handle the dash notation for minor chords
    if (modifiers.startsWith('-')) {
      modifiers = 'm' + modifiers.substring(1);
    }

    return note + modifiers;
  }

  // Use the original method as fallback for complex cases
  static String _fallbackNashvilleToChord(String nashvilleNumber, String key) {
    // Create a temporary mapping with just this one chord
    Map<String, String> tempResult = {};
    Map<String, dynamic> tempChords = {"0": nashvilleNumber};

    // Use the existing robust parsing function
    tempResult = parseChords(
      tempChords,
      {key: _nashvilleMappings![key]!},
      key,
      (msg) => print("ChordUtils: $msg"), // Simple logging function
    );

    // Return the parsed result or original if parsing failed
    return tempResult.isNotEmpty ? tempResult["0"]! : nashvilleNumber;
  }

  /// Convert a standard chord to Nashville notation in the specified key
  static String chordToNashville(String chord, String key) {
    _checkInitialized();

    if (chord == "N.C." || key.isEmpty) {
      return chord; // Return as-is for "No Chord" or if no key provided
    }

    // Validation for songKey
    if (!RegExp(r'^[A-G][#b]?$').hasMatch(key)) {
      throw FormatException('Invalid key format: $key');
    }

    // Handle slash chords (e.g., "C/G")
    if (chord.contains('/')) {
      List<String> parts = chord.split('/');
      if (parts.length == 2) {
        // Convert both parts of the slash chord independently
        String basePart = parts[0].trim();
        String bassPart = parts[1].trim();

        // Recursive call to convert each part
        String baseNashville = chordToNashville(basePart, key);

        // For the bass note, we need to extract just the Nashville number
        String bassNashville;
        if (bassPart.length == 1 ||
            (bassPart.length == 2 &&
                (bassPart[1] == '#' || bassPart[1] == 'b'))) {
          // If just a root note, convert normally
          bassNashville =
              chordToNashville(bassPart, key).replaceAll(RegExp(r'[^\d]'), '');
        } else {
          // If it has extensions, just use the root
          String bassRoot = bassPart.replaceAll(RegExp(r'[^A-Ga-g#b]'), '');
          bassNashville =
              chordToNashville(bassRoot, key).replaceAll(RegExp(r'[^\d]'), '');
        }

        return "$baseNashville/$bassNashville";
      }
    }

    // Extract root note and modifiers
    final rootNote = chord.replaceAll(RegExp(r'[^A-Ga-g#b]'), '');
    final modifiers = chord.substring(rootNote.length);

    // Find matching Nashville number
    String? nashvilleNumber;
    final keyMap = _nashvilleMappings![key];
    if (keyMap != null) {
      keyMap.forEach((number, note) {
        if (note.toLowerCase() == rootNote.toLowerCase()) {
          nashvilleNumber = number;
        }
      });
    }

    if (nashvilleNumber == null) {
      throw FormatException("Invalid Chord: $chord");
    }

    // Handle different types of chord modifiers
    String finalModifiers = modifiers;

    // Convert minor chords ("m") to Nashville "-"
    if (modifiers.startsWith('m') && !modifiers.startsWith('maj')) {
      finalModifiers = '-${modifiers.substring(1)}';
    }

    // Other modifiers (sus, dim, aug, etc.) can stay as is
    // Nashville notation uses the same notation for these

    return nashvilleNumber! + finalModifiers;
  }

  /// Check if the ChordUtils has been properly initialized
  static bool _checkInitialized() {
    if (!_initialized) {
      return false;
    }
    return true;
  }
}

/// Represents a chord position and value in a line of lyrics
class Chord {
  final int position;
  final String value;

  Chord({required this.position, required this.value});

  factory Chord.fromMap(MapEntry<String, dynamic> entry) {
    return Chord(
      position: int.parse(entry.key),
      value: entry.value.toString(),
    );
  }
  Chord copyWith({int? position, String? value}) {
    return Chord(
        position: position ?? this.position, value: value ?? this.value);
  }

  Map<String, String> toMap() => {position.toString(): value};
}

/// Represents a line in a song with lyrics and associated chords
class LineData {
  final String lyrics;
  final List<Chord> chords;

  LineData({required this.lyrics, required this.chords});

  factory LineData.fromMap(Map<String, dynamic> map) {
    final lyrics = map['lyrics'] ?? '';
    final chordMap = map['chords'] as Map<String, dynamic>? ?? {};

    final chords =
        chordMap.entries.map((entry) => Chord.fromMap(entry)).toList();

    return LineData(lyrics: lyrics, chords: chords);
  }

  Map<String, dynamic> toMap() => {
        'lyrics': lyrics,
        'chords': Map.fromEntries(
            chords.map((c) => MapEntry(c.position.toString(), c.value))),
      };
}

/// Represents a section in a song (verse, chorus, etc.)
class SongSection {
  final String title; // e.g., "Verse 1", "Chorus"
  final List<LineData> lines;

  SongSection({required this.title, required this.lines});

  factory SongSection.fromMap(MapEntry<String, dynamic> entry) {
    final title = entry.key;
    final lines = (entry.value as List)
        .map((lineMap) => LineData.fromMap(lineMap as Map<String, dynamic>))
        .toList();

    return SongSection(title: title, lines: lines);
  }

  Map<String, List<Map<String, dynamic>>> toMap() => {
        title: lines.map((line) => line.toMap()).toList(),
      };
}

/// Song header containing metadata
class SongHeader {
  final String name;
  final String key;
  final String? timeSignature;
  final int? bpm;
  final List<String> authors;

  SongHeader({
    required this.name,
    required this.key,
    this.timeSignature,
    this.bpm,
    this.authors = const [],
  });

  factory SongHeader.fromMap(Map<String, dynamic> map) {
    return SongHeader(
      name: map['name'] ?? 'Unnamed Song',
      key: map['key'] ?? 'C',
      timeSignature: map['time_signature'],
      bpm: map['bpm'],
      authors: List<String>.from(map['authors'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'key': key,
        if (timeSignature != null) 'time_signature': timeSignature,
        if (bpm != null) 'bpm': bpm,
        'authors': authors,
      };
}

/// Complete song data structure
class Song {
  final String hash;
  final SongHeader header;
  final List<SongSection> sections;

  Song({
    required this.hash,
    required this.header,
    required this.sections,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    final hash =
        map['hash'] ?? sha256.convert(utf8.encode(map.toString())).toString();

    final headerMap = map['header'] as Map<String, dynamic>? ?? {};
    final header = SongHeader.fromMap(headerMap);

    final sectionsMap = map['data'] as Map<String, dynamic>? ?? {};
    final sections =
        sectionsMap.entries.map((entry) => SongSection.fromMap(entry)).toList();

    return Song(hash: hash, header: header, sections: sections);
  }

  Map<String, dynamic> toMap() {
    final sectionMaps = <String, dynamic>{};
    for (var section in sections) {
      sectionMaps.addAll(section.toMap());
    }

    return {
      'hash': hash,
      'header': header.toMap(),
      'data': sectionMaps,
    };
  }

  int get sectionCount => sections.length;

  SongSection? getSection(int index) {
    if (index >= 0 && index < sections.length) {
      return sections[index];
    }
    return null;
  }

  isCorrupted() {
    return hash.isEmpty || header.name.isEmpty || sections.isEmpty;
  }

  factory Song.empty() {
    return Song(
      hash: sha256.convert(utf8.encode('empty')).toString(),
      header: SongHeader(name: '', key: 'C'),
      sections: [],
    );
  }
}

class SongData {
  final Map<String, List<String>> groups;
  final Map<String, Song> songs;

  SongData({required this.groups, required this.songs});

  factory SongData.fromDataProvider(
      Map<String, List<String>> groups, Map<String, Song> songs) {
    return SongData(groups: groups, songs: songs);
  }

  factory SongData.fromMap(Map<String, dynamic> map) {
    final groups = map['groups'] as Map<String, dynamic>? ?? {};
    final songs = map['songs'] as Map<String, dynamic>? ?? {};

    return SongData(
      groups: groups.map((key, value) =>
          MapEntry(key, List<String>.from(value.map((e) => e.toString())))),
      songs: songs.map((key, value) =>
          MapEntry(key, Song.fromMap(value as Map<String, dynamic>))),
    );
  }

  Map<String, dynamic> toMap() => {
        'groups': groups,
        'songs': Map.fromEntries(
            songs.entries.map((e) => MapEntry(e.key, e.value.toMap()))),
      };

  factory SongData.getEmptySongData() {
    return SongData(groups: {}, songs: {});
  }
}
