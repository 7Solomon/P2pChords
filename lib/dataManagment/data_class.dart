import 'dart:convert';

import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/chords_parsing.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/material.dart';

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

  toRawString() {
    String rawString = '';
    for (var section in sections) {
      rawString += [section.title].toString() + '\n';
      rawString += '\n';

      for (var line in section.lines) {
        String chordLine = '';
        for (var chord in line.chords) {
          while (line.chords.length < chord.position) {
            chordLine += ' ';
          }
          chordLine += chord.value;
        }
        rawString += chordLine + '\n';
        rawString += line.lyrics + '\n';

        rawString += '\n';
      }
    }
    return rawString;
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
