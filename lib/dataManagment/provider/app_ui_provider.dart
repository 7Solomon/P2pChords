import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
