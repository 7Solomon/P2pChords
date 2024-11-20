import 'dart:ffi';

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
  Map _uiSectionData = {};
  int _lengthOfSections = 2;
  int _startIndexofSection = 0;

  Map get songsDataMap => _songsDataMap;
  Map<String, Map<String, String>> get nashvileMappings => _nashvileMappings;
  String get currentGroup => _currentGroup;
  String get currentSongHash => _currentSongHash;
  String get currentKey => _currentKey;
  Map get uiSectionData => _uiSectionData;
  int get lengthOfSections => _lengthOfSections;
  int get startIndexofSection => _startIndexofSection;

  void getListOfDisplaySections(int currentIndex) {
    int maxLengthOfSections = _lengthOfSections;
    Map<String, List<int>> displaySections = {};

    List<String> songHashes = _songsDataMap.keys.toList();
    int startIndex = songHashes.indexOf(_currentSongHash);
    List<String> elementsAfterKey =
        startIndex != -1 ? songHashes.sublist(startIndex) : [];

    int sectionsAdded = 0;
    bool isFirstSong = true;
    bool needMoreSections = true;
    List<String> currentList = elementsAfterKey;

    while (needMoreSections) {
      for (String songHash in currentList) {
        int lengthOfCurrentSong = _songsDataMap[songHash]?['data']?.length ?? 0;
        int indexOfCurrentLength =
            displaySections.values.fold(0, (sum, list) => sum + list.length);

        int startingIndex = isFirstSong ? currentIndex : 0;

        List<int> sections = [];
        for (int i = startingIndex;
            i < lengthOfCurrentSong &&
                sections.length < maxLengthOfSections &&
                indexOfCurrentLength < maxLengthOfSections;
            i++) {
          sections.add(i);
        }

        // Handle remaining sections
        if (sectionsAdded + sections.length > maxLengthOfSections) {
          final int remainingSections = maxLengthOfSections - sectionsAdded;
          final List<int> takeSections = sections.sublist(0, remainingSections);
          displaySections[songHash] = takeSections;
          sectionsAdded += takeSections.length;
          needMoreSections = false;
          break;
        } else if (sections.isNotEmpty) {
          displaySections[songHash] = sections;
          sectionsAdded += sections.length;

          if (sectionsAdded >= maxLengthOfSections) {
            needMoreSections = false;
            break;
          }
        }

        isFirstSong = false;

        // If we've reached the end of the current list and still need more sections
        if (songHash == currentList.last &&
            sectionsAdded < maxLengthOfSections) {
          currentList = songHashes;
          if (displaySections.length >= songHashes.length) {
            //  Is good to have this check, because loop dont go vroooom
            needMoreSections = false;
            break;
          }
        }
      }
    }

    _startIndexofSection = currentIndex;
    _uiSectionData = displaySections;
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
        notifyListeners();
      } else {
        _startIndexofSection = 0;
        getListOfDisplaySections(_startIndexofSection);
        notifyListeners();
      }
    } else {
      getListOfDisplaySections(_startIndexofSection - 1);
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
        notifyListeners();
      } else {
        _currentSongHash = _songsDataMap.keys.toList()[
            _songsDataMap.keys.toList().indexOf(_currentSongHash) + 1];
        _startIndexofSection = 0;
        getListOfDisplaySections(_startIndexofSection);
        notifyListeners();
      }
    } else {
      getListOfDisplaySections(_startIndexofSection + 1);
      notifyListeners();
    }
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
