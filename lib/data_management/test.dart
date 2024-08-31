import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'data_type.dart';

class DataManager {
  static const String _key = '';

  static Future<void> saveData(SongData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data.toJson());
    await prefs.setString(_key, jsonString);
  }

  static Future<SongData?> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      return SongData.fromJson(json);
    }
    return null;
  }
}
