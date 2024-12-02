import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';

class UiSettings extends ChangeNotifier {
  //ThemeMode _themeMode = ThemeMode.system;
  //double _fontSize = 14.0;
  Map<String, Map> _songsDataMap = {};
  //Map<String, List> _groupSongMap = {};
  String _currentGroup = "";
  String _currentSongHash = "";
  String _currentKey = "C";

  ///
  Map<String, Map<String, String>> _nashvileMappings = {};
  //Map _uiSectionData = {};
  List<Map<String, List<int>>> _uiSectionData = [];
  int _lengthOfSectionsRow = 1;
  int _lengthOfSectionColumns = 2;
  int _startIndexofSection = 0;

  Map get songsDataMap => _songsDataMap;
  Map<String, Map<String, String>> get nashvileMappings => _nashvileMappings;
  String get currentGroup => _currentGroup;
  String get currentSongHash => _currentSongHash;
  String get currentKey => _currentKey;
  //Map get uiSectionData => _uiSectionData;
  List get uiSectionData => _uiSectionData;
  int get lengthOfSectionsRow => _lengthOfSectionsRow;
  int get startIndexofSection => _startIndexofSection;

  void getListOfDisplaySections(int currentIndex) {
    //print("Starting with currentIndex: $currentIndex");

    // Early return if no songs
    if (_songsDataMap.isEmpty) {
      //print("_songsDataMap is empty!");
      _uiSectionData = [];
      return;
    }

    int maxLengthOfSections = _lengthOfSectionsRow * _lengthOfSectionColumns;
    //print("maxLengthOfSections: $maxLengthOfSections");

    Map<String, List<int>> displaySections = {};

    List<String> songHashes = _songsDataMap.keys.toList();
    //print("songHashes: $songHashes");

    // Handle case where current song isn't in the map
    int startIndex = songHashes.indexOf(_currentSongHash);
    if (startIndex == -1) {
      //print("Current song hash not found in map, using first song");
      startIndex = 0;
      _currentSongHash = songHashes.first;
    }
    //print("startIndex: $startIndex, _currentSongHash: $_currentSongHash");

    // Create ordered list safely
    List<String> orderedHashes = [
      ...songHashes.sublist(startIndex),
      if (startIndex > 0) ...songHashes.sublist(0, startIndex)
    ];
    //print("orderedHashes: $orderedHashes");

    // Rest of your function remains the same...
    int sectionsAdded = 0;
    bool isFirstSong = true;

    for (String songHash in orderedHashes) {
      if (sectionsAdded >= maxLengthOfSections) break;

      int lengthOfCurrentSong = _songsDataMap[songHash]?['data']?.length ?? 0;
      int startingIndex = isFirstSong ? currentIndex : 0;

      List<int> sections = [];
      for (int i = startingIndex;
          i < lengthOfCurrentSong &&
              sectionsAdded < maxLengthOfSections &&
              sections.length < maxLengthOfSections;
          i++) {
        sections.add(i);
        sectionsAdded++;
      }

      if (sections.isNotEmpty) {
        displaySections[songHash] = sections;
      }

      isFirstSong = false;
    }

    final flatList = displaySections.entries.expand((entry) {
      return entry.value.map((value) => MapEntry(entry.key, value));
    }).toList();

    final columnSections = List.generate(
        (flatList.length / _lengthOfSectionColumns).ceil(), (columnIndex) {
      final startIndex = columnIndex * _lengthOfSectionColumns;
      final endIndex =
          min(startIndex + _lengthOfSectionColumns, flatList.length);
      final chunk = flatList.sublist(startIndex, endIndex);

      return chunk.fold<Map<String, List<int>>>(
        {},
        (columnMap, item) => columnMap
          ..update(
            item.key,
            (list) => list..add(item.value),
            ifAbsent: () => [item.value],
          ),
      );
    });

    //print("Final columnSections: $columnSections");
    _startIndexofSection = currentIndex;
    _uiSectionData = columnSections;
  }

  void updateListOfDisplaySectionsUp() {
    if (!(_startIndexofSection - 1 > 0)) {
      if (_songsDataMap.keys.toList().indexOf(_currentSongHash) > 0) {
        // Set New Key and Index 0 if the start is reached and this is not the first song
        _currentSongHash = _songsDataMap.keys.toList()[
            _songsDataMap.keys.toList().indexOf(_currentSongHash) - 1];
        _startIndexofSection = _songsDataMap[_currentSongHash]!['data']
            .length; // Vielleicht -1 und ! kann zu Red Screen führen???
        // Update Section
        getListOfDisplaySections(_startIndexofSection - 1);
        //getListOfDisplaySectionsExperimental(_startIndexofSection - 1);
        notifyListeners();
      } else {
        _startIndexofSection = 0;
        getListOfDisplaySections(_startIndexofSection);
        //getListOfDisplaySectionsExperimental(_startIndexofSection);
        notifyListeners();
      }
    } else {
      getListOfDisplaySections(_startIndexofSection - 1);
      //getListOfDisplaySectionsExperimental(_startIndexofSection - 1);
      notifyListeners();
    }
  }

  void updateListOfDisplaySectionsDown() {
    if (_startIndexofSection + 1 > // ! kann zu Not Good Screen führen???
        _songsDataMap[_currentSongHash]!['data'].length - 1) {
      if (_songsDataMap.keys.toList().indexOf(_currentSongHash) >=
          _songsDataMap.keys.toList().length - 1) {
        _currentSongHash = _songsDataMap.keys.toList()[0];
        _startIndexofSection = 0;
        getListOfDisplaySections(_startIndexofSection);
        //getListOfDisplaySectionsExperimental(_startIndexofSection);
        notifyListeners();
      } else {
        _currentSongHash = _songsDataMap.keys.toList()[
            _songsDataMap.keys.toList().indexOf(_currentSongHash) + 1];
        _startIndexofSection = 0;
        getListOfDisplaySections(_startIndexofSection);
        //getListOfDisplaySectionsExperimental(_startIndexofSection);
        notifyListeners();
      }
    } else {
      getListOfDisplaySections(_startIndexofSection + 1);
      //getListOfDisplaySectionsExperimental(_startIndexofSection + 1);
      notifyListeners();
    }
  }

  void setSongsDataMap(Map<String, Map> data) {
    if (_songsDataMap == data) return;
    _songsDataMap = data;
    notifyListeners();
  }

  void setCurrentGroup(String group) {
    if (_currentGroup == group && group != '') return;
    print(group);
    _currentGroup = group;
    notifyListeners();
  }

  void setCurrentSong(String songHash) {
    if (_currentSongHash == songHash) return;
    _currentSongHash = songHash;
    notifyListeners();
  }

  void setCurrentKey(String key) {
    _currentKey = key;
    notifyListeners();
  }

  void setNashvileMappings(Map<String, Map<String, String>> map) {
    _nashvileMappings = map;
    notifyListeners();
  }

  //void setUiSectionDataAndIndex(Map data, int index) {
  //  _startIndexofSection = index;
  //  _uiSectionData = data;
  //  notifyListeners();
  //}
}
