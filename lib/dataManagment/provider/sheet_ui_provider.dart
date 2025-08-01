import 'dart:convert';
import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SheetUiProvider extends ChangeNotifier {
  SheetUiProvider() {
    _loadFromPrefs();
  }

  //String _currentKey = 'C';
  Map<String, String> _currentKeyMap = {};
  UiVariables _uiVariables = UiVariables();

  void setFontSize(double size) {
    _uiVariables.fontSize.value = size;
    notifyListeners();
  }

  void setSectionCount(int count) {
    _uiVariables.sectionCount.value = count;

    notifyListeners();
  }

  //void setCurrentKey(String key) {
  //  _currentKeyMap[key] = key;
  //  notifyListeners();
  //}

  void setCurrentSongKeyInMap(String songHash, String key) {
    _currentKeyMap[songHash] = key;
    notifyListeners();
  }

  void setUiVariables(UiVariables uiVariables) {
    _uiVariables = uiVariables;
    notifyListeners();
  }

  UiVariables get uiVariables => _uiVariables;
  //String get currentKey => _currentKey;
  Map<String, String> get currentKeyMap => _currentKeyMap;
  String getCurrentKeyForSong(String songHash) {
    return _currentKeyMap[songHash] ?? 'C';
  }

  fromJson(Map<String, dynamic> json) {
    //_currentKey = json['currentKey'];
    _currentKeyMap = Map<String, String>.from(json['currentKeyMap'] ?? {});
    _uiVariables = UiVariables.fromJson(json['uiVariables']);
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      //'currentKey': _currentKe
      'currentKeyMap': _currentKeyMap,
      'uiVariables': _uiVariables.toJson(),
    };
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(toJson());
      //print('Saving SheetUiProvider state: $jsonData');
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

      if (jsonData != null && jsonData.isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonData);
          fromJson(data);
        } catch (e) {
          debugPrint('Error parsing SheetUiProvider JSON: $e');
          // Reset to default values and save those back to preferences
          //_currentKey = 'C';
          _currentKeyMap = {};
          _uiVariables = UiVariables();
          saveToPrefs();
        }
      }
    } catch (e) {
      debugPrint('Error loading SheetUiProvider state: $e');
    }
  }
}
