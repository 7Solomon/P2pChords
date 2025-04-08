import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/styling/Themes.dart';

class AppUiProvider extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.trueTheme;

  AppUiProvider() {
    _loadFromPrefs();
  }

  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    _saveToPrefs();
    notifyListeners();
  }

  ThemeData? get currentTheme => _currentTheme;

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Save theme as a string identifier
    String themeName = _currentTheme == AppTheme.trueTheme
        ? 'true'
        : 'dark'; //  Muss überarbeitet werden is quatschig
    await prefs.setString('AppTheme', themeName);
  }

  // Load theme preference
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeName = prefs.getString('AppTheme') ?? 'true';
      _currentTheme =
          themeName == 'true' ? AppTheme.trueTheme : AppTheme.darkTheme;
      notifyListeners();
    } catch (e) {
      _currentTheme = AppTheme.trueTheme;
    }
  }
}

class SheetUiProvider extends ChangeNotifier {
  SheetUiProvider() {
    _loadFromPrefs();
  }

  String _currentKey = 'C';
  UiVariables _uiVariables = UiVariables(
    fontSize: 16.0,
    lineSpacing: 0.0,
    sectionCount: 1,
  );

  void setFontSize(double size) {
    _uiVariables.fontSize.value = size;
    notifyListeners();
  }

  void setSectionCount(int count) {
    _uiVariables.sectionCount.value = count;

    notifyListeners();
  }

  void setCurrentKey(String key) {
    _currentKey = key;
    notifyListeners();
  }

  void setUiVariables(UiVariables uiVariables) {
    _uiVariables = uiVariables;
    notifyListeners();
  }

  UiVariables get uiVariables => _uiVariables;
  String get currentKey => _currentKey;

  fromJson(Map<String, dynamic> json) {
    _currentKey = json['currentKey'];
    _uiVariables = UiVariables.fromJson(json['uiVariables']);
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'currentKey': _currentKey,
      'uiVariables': _uiVariables.toJson(),
    };
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(toJson());
      await prefs.setString('sheet_ui_settings', jsonData);
    } catch (e) {
      debugPrint('Error saving SheetUiProvider state: $e');
    }
  }

  // Load from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonData = prefs.getString('sheet_ui_settings');

      if (jsonData != null) {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading SheetUiProvider state: $e');
    }
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

  String? getGroupOfSong(String hash) {
    /* Just first group that contains the song 
    Musst aufpassen du kek
    */
    for (var group in _groups!.keys) {
      if (_groups![group]!.contains(hash)) {
        return group;
      }
    }
    return null;
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
