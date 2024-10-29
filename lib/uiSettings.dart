import 'package:flutter/material.dart';

class UiSettings extends ChangeNotifier {
  //ThemeMode _themeMode = ThemeMode.system;
  //double _fontSize = 14.0;
  int secctionIndexSize = 2;

  //ThemeMode get themeMode => _themeMode;
  //double get fontSize => _fontSize;

  void setsecctionIndexSize(int siz) {
    secctionIndexSize = siz;
    notifyListeners();
  }
}
