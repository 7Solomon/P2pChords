import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  UiVariables _uiVariables = UiVariables();

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

  void setCurrentSong(String? songHash) {
    _currentSongHash = songHash;
    notifyListeners();
  }

  void setCurrentGroup(String? group) {
    _currentGroup = group;
    notifyListeners();
  }

  void setCurrentSectionIndex(int? index) {
    _currentSectionIndex = index;
    notifyListeners();
  }
  //////
  // QUATSCHIG!!!
  /////
  //Future<bool> validateSelection(
  //  BuildContext context, {
  //  bool autoSelect = true,
  //  bool removeInvalidSongs = false,
  //  bool showSnackbar = false,
  //  bool navigateBack = false,
  //}) async {
  //  final dataLoader = Provider.of<DataLoadeProvider>(context, listen: false);
  //  final currentSelection =
  //      Provider.of<CurrentSelectionProvider>(context, listen: false);
  //  bool changed = false;
  //  String? hashToRemove;
//
  //  // Validate song selection
  //  if (_currentSongHash != null &&
  //      !dataLoader.songs.containsKey(_currentSongHash)) {
  //    hashToRemove = _currentSongHash;
  //    _currentSongHash = null;
  //    _currentSectionIndex = null;
  //    changed = true;
  //  }
//
  //  // Validate group selection
  //  if (_currentGroup != null &&
  //      !dataLoader.groups.containsKey(_currentGroup)) {
  //    _currentGroup = null;
  //    changed = true;
  //  }
//
  //  // Auto-select if requested
  //  if (changed && autoSelect) {
  //    if (dataLoader.groups.isNotEmpty) {
  //      //String firstGroup = dataLoader.groups.keys.first;
  //      //_currentGroup = firstGroup;
//
  //      if (dataLoader.groups[currentSelection.currentGroup]?.isNotEmpty ??
  //          false) {
  //        String? firstSongHash =
  //            dataLoader.getHashByIndex(currentSelection.currentGroup!, 0);
  //        if (firstSongHash != null) {
  //          _currentSongHash = firstSongHash;
  //          _currentSectionIndex = 0;
  //        }
  //      }
  //    }
  //  }
//
  //  // Remove invalid song if requested
  //  if (removeInvalidSongs && hashToRemove != null) {
  //    await dataLoader.removeSong(hashToRemove);
  //    if (showSnackbar) {
  //      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //          content: Text('Ungültiges Lied gefunden und entfernt!!')));
  //    }
  //  }
//
  //  // Navigate back if requested
  //  if (navigateBack && changed) {
  //    Navigator.of(context).pop();
  //  }
//
  //  if (changed) {
  //    notifyListeners();
  //  }
//
  //  return changed;
  //}

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
  bool _initialized = false;

  // Provide safer access methods
  Map<String, List<String>> get groups => _groups ?? {};
  Map<String, Song> get songs => _songs ?? {};
  bool get isInitialized => _initialized;

  // Constructor that initializes and loads data
  DataLoadeProvider() {
    initializeData();
  }

  // Initialize with a clear state
  Future<void> initializeData() async {
    await _loadDataFromStorage();
  }

  // Function to load data from SharedPreferences
  Future<void> _loadDataFromStorage() async {
    isLoading = true;
    notifyListeners();

    try {
      SongData groupsData = await MultiJsonStorage.getSavedSongsData();
      _groups = groupsData.groups;
      _songs = groupsData.songs;
      _initialized = true;
    } catch (e) {
      _groups = {};
      _songs = {};
      debugPrint('Error loading data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // CRUD Operations with storage sync
  Future<void> addSong(Song song, String groupName) async {
    _songs ??= {};
    _groups ??= {};

    _songs![song.hash] = song;

    _groups!.putIfAbsent(groupName, () => []);
    if (!_groups![groupName]!.contains(song.hash)) {
      _groups![groupName]!.add(song.hash);
    }

    await _syncToStorage();
    notifyListeners();
  }

  Future<void> removeSong(String hash) async {
    if (_songs == null || !_songs!.containsKey(hash)) return;

    _songs!.remove(hash);

    // Remove all references to this song from groups
    if (_groups != null) {
      for (final groupName in _groups!.keys) {
        _groups![groupName]?.remove(hash);
      }
    }

    await _syncToStorage();
    notifyListeners();
  }

  Future<void> removeGroup(String groupName) async {
    if (_groups == null || !_groups!.containsKey(groupName)) return;

    _groups!.remove(groupName);

    // Optional: Clean up orphaned songs (songs not in any group)
    if (_songs != null) {
      final allSongHashes = <String>{};
      for (final songs in _groups!.values) {
        allSongHashes.addAll(songs);
      }

      _songs!.removeWhere((hash, _) => !allSongHashes.contains(hash));
    }

    await _syncToStorage();
    notifyListeners();
  }

  Future<void> addSongsData(SongData songdata) async {
    _songs ??= {};
    _groups ??= {};

    for (var group in songdata.groups.entries) {
      _groups!.putIfAbsent(group.key, () => []);
      for (String hash in group.value) {
        if (!_groups![group.key]!.contains(hash)) {
          _groups![group.key]!.add(hash);
        }
        _songs![hash] = songdata.songs[hash]!;
      }
    }

    await _syncToStorage();
    notifyListeners();
  }

  Future<void> _syncToStorage() async {
    try {
      if (_songs != null && _groups != null) {
        final songData = SongData.fromDataProvider(_groups!, _songs!);
        await MultiJsonStorage.saveSongsData(songData);
      }
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  Future<void> refreshData() async {
    await _loadDataFromStorage();
  }

  Song? getSongByHash(String hash) {
    return _songs?[hash];
  }

  int getSongIndex(String group, String hash) {
    if (_groups == null || !_groups!.containsKey(group)) return -1;
    return _groups![group]?.indexOf(hash) ?? -1;
  }

  String? getHashByIndex(String group, int index) {
    if (_groups == null || !_groups!.containsKey(group)) return null;
    final groupSongs = _groups![group]!;
    if (index < 0 || index >= groupSongs.length) return null;
    return groupSongs[index];
  }

  List<Song> getSongsInGroup(String group) {
    List<String> songHashes = _groups?[group] ?? [];
    List<Song> result = [];

    for (var hash in songHashes) {
      final song = _songs?[hash];
      if (song != null) {
        result.add(song);
      }
    }

    return result;
  }

  String? getGroupOfSong(String hash) {
    if (_groups == null) return null;

    for (var group in _groups!.keys) {
      if (_groups![group]?.contains(hash) == true) {
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
}
