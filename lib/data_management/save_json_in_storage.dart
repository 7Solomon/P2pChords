import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MultiJsonStorage {
  static const String _keyPrefix = 'json_storage_';
  //static const String _indexKey = 'json_storage_index';
  static const String _groupIndexKey = 'json_storage_group_index';

  static Future<bool> saveJson(String key, Map<String, dynamic> jsonData,
      {String group = 'default'}) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(jsonData);
    bool result = await prefs.setString('$_keyPrefix$group:$key', jsonString);
    if (result) {
      await _updateIndex(key, group, true);
    }
    return result;
  }

  static Future<Map<String, dynamic>?> loadJson(String key,
      {String group = 'default'}) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('$_keyPrefix$group:$key');
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  static Future<bool> removeJson(String key, {String group = 'default'}) async {
    final prefs = await SharedPreferences.getInstance();
    bool result = await prefs.remove('$_keyPrefix$group:$key');
    if (result) {
      await _updateIndex(key, group, false);
    }
    return result;
  }

  static Future<Map<String, List<String>>> getAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? groupIndex =
        jsonDecode(prefs.getString(_groupIndexKey) ?? '{}');
    //print(groupIndex!
    //    .map((key, value) => MapEntry(key, List<String>.from(value))));
    return groupIndex!
        .map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  static Future<List<String>> getAllKeys({String group = 'default'}) async {
    final groupMap = await getAllGroups();
    return groupMap[group] ?? [];
  }

  static Future<Map<String, Map<String, dynamic>>> loadAllJson(
      {String group = 'default'}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> keys = await getAllKeys(group: group);
    Map<String, Map<String, dynamic>> result = {};
    for (String key in keys) {
      String? jsonString = prefs.getString('$_keyPrefix$group:$key');
      if (jsonString != null) {
        result[key] = jsonDecode(jsonString);
      }
    }
    return result;
  }

  static Future<void> _updateIndex(String key, String group, bool add) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> groupIndex =
        jsonDecode(prefs.getString(_groupIndexKey) ?? '{}');

    if (!groupIndex.containsKey(group)) {
      groupIndex[group] = [];
    }

    List<String> groupKeys = List<String>.from(groupIndex[group]);

    if (add && !groupKeys.contains(key)) {
      groupKeys.add(key);
    } else if (!add) {
      groupKeys.remove(key);
    }

    groupIndex[group] = groupKeys;
    await prefs.setString(_groupIndexKey, jsonEncode(groupIndex));
  }
}
