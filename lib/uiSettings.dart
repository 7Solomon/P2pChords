import 'dart:ffi';

import 'package:flutter/material.dart';

class UiSettings extends ChangeNotifier {
  //ThemeMode _themeMode = ThemeMode.system;
  //double _fontSize = 14.0;
  Map<String, Map> _songsDataMap = {};
  Map<String, List> _groupSongMap = {};
  String _currentGroup = "";
  String _currentSongHash = "";
  String _currentKey = "C";

  ///
  Map _UiSectionData = {};
  int _lengthOfSections = 4;
  int _sectionsAdded = 0;
  int _startIndexofSection = 0;

  Map get songsDataMap => _songsDataMap;
  Map<String, List> get groupSongMap => _groupSongMap;
  String get currentGroup => _currentGroup;
  String get currentSongHash => _currentSongHash;
  String get currentKey => _currentKey;
  Map get UiSectionData => _UiSectionData;

  //ThemeMode get themeMode => _themeMode;
  //double get fontSize => _fontSize;

  //String giveHashAfterHash(String hash) {
  //  List keys = _songsDataMap.keys.toList();
  //  int currentIndex = keys.indexOf(hash);

  //  if (currentIndex != -1 && currentIndex < keys.length - 1) {
  //    String nextKey = keys[currentIndex + 1];
  //    return nextKey;
  //  } else {
  //    String firstKey = keys[0];
  //    return firstKey;
  //  }
  //}
  void getListOfDisplaySections(
    int currentIndex,
  ) {
    int maxLengthOfSections =
        _lengthOfSections; // Fixed length of sections to display
    Map<String, List<int>> displaySections = {};
    // List of Songs after the current song
    List<String> songHashes = _songsDataMap.keys.toList();
    int startIndex = songHashes.indexOf(_currentSongHash);
    List<String> elementsAfterKey =
        startIndex != -1 ? songHashes.sublist(startIndex + 1) : [];
    //print('Elements after Key: $elementsAfterKey');
    int sectionsAdded = 0;
    bool isFirstSong = true; // Flag to track the first song
    print('Current Index: $currentIndex');
    for (String songHash in elementsAfterKey) {
      // Determine the length of the current song's data
      int lengthOfCurrentSong = _songsDataMap[songHash]?['data']?.length ?? 0;
      int indexOfCurrentLength =
          displaySections.values.fold(0, (sum, list) => sum + list.length);
      print('Index of Current Length: $indexOfCurrentLength');
      // Set the starting index depending on whether it's the first song
      int startIndex = isFirstSong ? currentIndex : 0;

      // Calculate the section indices for the current song
      List<int> sections = [];
      for (int i = startIndex;
          i < lengthOfCurrentSong &&
              sections.length < maxLengthOfSections &&
              indexOfCurrentLength < maxLengthOfSections;
          i++) {
        sections.add(i);
      }

      // Stop if we've reached the required number of sections
      print(
          'sectionsAdded: $sectionsAdded, maxLengthOfSections: $maxLengthOfSections');
      if (sectionsAdded > maxLengthOfSections) {
        final int div = sectionsAdded - maxLengthOfSections;
        print('Div: $div');
        final List<int> takeSections = sections.sublist(0, div);
        print('Take Sections: $takeSections');
        displaySections[songHash] = takeSections;
        break;
      } else if (sections.isNotEmpty) {
        displaySections[songHash] = sections;
        sectionsAdded += sections.length;
      }

      // Set isFirstSong to false after the first iteration
      isFirstSong = false;
    }

    _startIndexofSection = currentIndex;
    _UiSectionData = displaySections;
    print('Display Sections: $_UiSectionData');
  }

  void updateListOfDisplaySectionsUp() {
    getListOfDisplaySections(_startIndexofSection + 1);
    notifyListeners();
  }

  void updateListOfDisplaySectionsDown() {
    getListOfDisplaySections(_startIndexofSection - 1);
    notifyListeners();
  }

  void setSongsDataMap(Map<String, Map> data) {
    _songsDataMap = data;
    notifyListeners();
  }

  void setCurrentGroup(String group) {
    _currentGroup = group;
    notifyListeners();
  }

  void setCurrentSong(String songHash) {
    _currentSongHash = songHash;
    notifyListeners();
  }

  void setCurrentKey(String key) {
    _currentKey = key;
    notifyListeners();
  }

  void setGroupSongMap(Map<String, List> data) {
    _groupSongMap = data;
    notifyListeners();
  }
}
