import 'dart:convert';

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

    // Extract base number and modifiers
    final baseNumber = nashvilleNumber.replaceAll(RegExp(r'[^\d]'), '');
    final modifiers = nashvilleNumber.replaceAll(RegExp(r'\d'), '');

    // Get the root note from mappings
    final rootNote = _nashvilleMappings![key]?[baseNumber];
    if (rootNote == null) {
      return nashvilleNumber; // Return original if not found
    }
    return rootNote + modifiers;
  }

  /// Convert a standard chord to Nashville notation in the specified key
  static String chordToNashville(String chord, String key) {
    _checkInitialized();

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

    // Return Nashville notation or original chord if not found
    return nashvilleNumber != null ? nashvilleNumber! + modifiers : chord;
  }

  /// Check if the ChordUtils has been properly initialized
  static bool _checkInitialized() {
    if (!_initialized) {
      print('ChordUtils not initialized! Call ChordUtils.initialize() first.');
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

  Map<String, String> toMap() => {position.toString(): value};
}

/// Represents a line in a song with lyrics and associated chords
class LyricLine {
  final String lyrics;
  final List<Chord> chords;

  LyricLine({required this.lyrics, required this.chords});

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    final lyrics = map['lyrics'] ?? '';
    final chordMap = map['chords'] as Map<String, dynamic>? ?? {};

    final chords =
        chordMap.entries.map((entry) => Chord.fromMap(entry)).toList();

    return LyricLine(lyrics: lyrics, chords: chords);
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
  final List<LyricLine> lines;

  SongSection({required this.title, required this.lines});

  factory SongSection.fromMap(MapEntry<String, dynamic> entry) {
    final title = entry.key;
    final lines = (entry.value as List)
        .map((lineMap) => LyricLine.fromMap(lineMap as Map<String, dynamic>))
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

  // Helper methods
  int get sectionCount => sections.length;

  /// Get a specific section by index, safely returns null if out of bounds
  SongSection? getSection(int index) {
    if (index >= 0 && index < sections.length) {
      return sections[index];
    }
    return null;
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
}
