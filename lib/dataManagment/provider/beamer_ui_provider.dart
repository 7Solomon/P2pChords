import 'dart:convert';
import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeamerUiProvider with ChangeNotifier {
  static const String _prefsKey = 'beamerUiSettings';
  BeamerUiVariables _uiVariables = BeamerUiVariables();

  BeamerUiVariables get uiVariables => _uiVariables;

  BeamerUiProvider() {
    loadFromPrefs();
  }

  void setUiVariables(BeamerUiVariables newVariables) {
    if (_uiVariables.isDifferent(newVariables)) {
      _uiVariables = newVariables;
      notifyListeners();
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsString = prefs.getString(_prefsKey);
    if (settingsString != null) {
      try {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsString);
        _uiVariables = BeamerUiVariables.fromJson(settingsMap);
      } catch (e) {
        // Handle potential decoding errors, maybe reset to default
        _uiVariables = BeamerUiVariables();
      }
    } else {
      // No settings saved yet, use defaults
      _uiVariables = BeamerUiVariables();
    }
    notifyListeners(); // Notify listeners after loading
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String settingsString = jsonEncode(_uiVariables.toJson());
    await prefs.setString(_prefsKey, settingsString);
  }
}
