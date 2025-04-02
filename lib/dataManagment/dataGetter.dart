import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/dataManagment/dataClass.dart';

class UIProvider extends ChangeNotifier {
  String? _currentKey;
  double? _fontSize;
  int? _sectionCount;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setSectionCount(int count) {
    _sectionCount = count;
    notifyListeners();
  }

  void setCurrentKey(String key) {
    _currentKey = key;
    notifyListeners();
  }

  double? get fontSize => _fontSize;
  String? get currentKey => _currentKey;
  int? get sectionCount => _sectionCount;

  fromJson(Map<String, dynamic> json) {
    _currentKey = json['currentKey'];
    _fontSize = json['fontSize'];
    _sectionCount = json['sectionCount'];
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'currentKey': _currentKey,
      'fontSize': _fontSize,
      'sectionCount': _sectionCount
    };
  }
}

class CurrentSelectionProvider extends ChangeNotifier {
  String? _currentSongHash;
  String? _currentGroup;
  int? _currentSectionIndex;

  String? get currentSongHash => _currentSongHash;
  String? get currentGroup => _currentGroup;
  int? get currentSectionIndex => _currentSectionIndex;

  void setCurrentSong(String songHash) {
    _currentSongHash = songHash;
    notifyListeners();
  }

  void setCurrentGroup(String group) {
    _currentGroup = group;
    notifyListeners();
  }

  void setCurrentSectionIndex(int index) {
    _currentSectionIndex = index;
    notifyListeners();
  }

  fromJson(Map<String, dynamic> json) {
    _currentSongHash = json['currentSongHash'];
    _currentGroup = json['currentGroup'];
    _currentSectionIndex = json['currentSectionIndex'];
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'currentSongHash': _currentSongHash,
      'currentGroup': _currentGroup,
      'currentSectionIndex': _currentSectionIndex,
    };
  }
}

class DataLoadeProvider extends ChangeNotifier {
  Map<String, List<String>>? _groups;
  Map<String, Song>? _songs;
  bool isLoading = false;

  // Constructor that initializes and loads data
  DataLoadeProvider() {
    _loadDataFromStorage();
  }

  // Function to load data from SharedPreferences
  Future<void> _loadDataFromStorage() async {
    isLoading = true;
    notifyListeners();

    try {
      SongData groupsData = await MultiJsonStorage.getSavedSongsData();
      _groups = groupsData.groups;
      _songs = groupsData.songs;
    } catch (e) {
      throw ('Error loading data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveDataToStorage(SongData songData) async {
    await MultiJsonStorage.saveSongsData(songData);
  }

  Future<void> refreshData() async {
    await _loadDataFromStorage();
  }

  Song getSongByHash(String hash) {
    return _songs![hash]!;
  }

  int getSongIndex(String group, String hash) {
    return _groups![group]!.indexOf(hash);
  }

  String getHashByIndex(String group, int index) {
    return _groups![group]![index];
  }

  List<Song> getSongsInGroup(String group) {
    List<String> songHashes = _groups![group] ?? [];
    return songHashes.map((hash) => _songs![hash]!).toList();
  }

  SongData getSongData(String group) {
    List<Song> songs = getSongsInGroup(group);
    Map<String, List<String>> groups = Map<String, List<String>>.from(
        {group: songs.map((e) => e.hash).toList()});
    return SongData.fromDataProvider(groups, _songs!);
  }

  Map<String, dynamic>? get groups => _groups;
  Map<String, Song>? get songs => _songs;
}
