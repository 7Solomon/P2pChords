import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crypto/crypto.dart'; // Add this package to generate the hash

class MultiJsonStorage {
  static const String _keyPrefix = 'json_storage_songs_';
  static const String _groupPrefix = 'json_storage_groups_';

  // For debug
  static Future<void> printAllWithPrefix() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys(); // Retrieve all keys stored in SharedPreferences

    // Iterate through all keys and check if they start with the given prefix
    for (String key in keys) {
      String? value = prefs.getString(key);
      print('Key: $key, Value: $value');
    }
  }

  static Future<Map<String, dynamic>> saveJson(
      String displayName, Map<String, dynamic> jsonData,
      {String group = 'default', String jsonHash = 'undefined'}) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert the JSON data to string
    String jsonString = jsonEncode(jsonData);
    if (jsonHash == 'undefined') {
      jsonHash = md5.convert(utf8.encode(jsonString)).toString();
    }

    // Speichern der Json unter dem Hash Key
    bool result = await prefs.setString('$_keyPrefix:$jsonHash', jsonString);

    if (result) {
      // Retrieve the map of groups to hashes
      String? groupMapString = prefs.getString('$_groupPrefix:group_map');
      Map<String, List<Map<String, String>>> groupMap = {};

      // If the map exists, decode it
      if (groupMapString != null) {
        Map<String, dynamic> decodedMap = jsonDecode(groupMapString);
        groupMap = decodedMap.map((key, value) {
          return MapEntry(
            key,
            (value as List<dynamic>)
                .map((item) => Map<String, String>.from(item))
                .toList(),
          );
        });
      }

      // Get the list of hashes associated with the group, or create a new list
      List<Map<String, String>> songMap = groupMap[group] ?? [];
      // Add the hash to the group if it's not already there
      if (!songMap.any((map) => map['hash'] == jsonHash)) {
        songMap.add({'name': displayName, 'hash': jsonHash});
      }

      // Update the group map with the new list of hashes
      groupMap[group] = songMap;

      // Save the updated group map back to SharedPreferences
      await prefs.setString('$_groupPrefix:group_map', jsonEncode(groupMap));
    }

    return {'result': result, 'hash': jsonHash};
  }

  static Future<void> saveNewGroup(String name) async {
    final prefs = await SharedPreferences.getInstance();
    String? groupMapString = prefs.getString('$_groupPrefix:group_map');

    if (groupMapString != null) {
      Map<String, dynamic> decodedMap = jsonDecode(groupMapString);
      if (!decodedMap.containsKey(name)) {
        decodedMap[name] = [];
        await prefs.setString(
            '$_groupPrefix:group_map', jsonEncode(decodedMap));
      }
    } else {
      Map<String, dynamic> decodedMap = {};
      decodedMap[name] = [];
      await prefs.setString('$_groupPrefix:group_map', jsonEncode(decodedMap));
    }
  }

  static Future<void> saveJsonsGroup(
      String groupName, Map groupSongData) async {
    saveNewGroup(groupName); // MAybe not gooooood
    for (MapEntry entry in groupSongData.entries) {
      String name = entry.value['header']['name'] ?? 'No name';
      await saveJson(name, entry.value, group: groupName, jsonHash: entry.key);
    }
  }

  static Future<Map<String, dynamic>?> loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('$_keyPrefix:$key');
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  static Future<bool> removeJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    bool result = await prefs.remove('$_keyPrefix:$key');
    return result;
  }

  static Future<bool> removeJsonFromGroup(String group, String jsonHash) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the current group map
    String? groupMapString = prefs.getString('$_groupPrefix:group_map');
    if (groupMapString == null) {
      return false; // Group map does not exist
    }

    Map<String, dynamic> groupMap = jsonDecode(groupMapString);

    // Check if the group exists
    if (!groupMap.containsKey(group)) {
      return false; // Group does not exist
    }

    // Get the list of songs in the group
    List<Map<String, String>> songMap = (groupMap[group] as List<dynamic>)
        .map((item) => Map<String, String>.from(item))
        .toList();

    // Remove the song from the group based on the hash
    songMap.removeWhere((map) => map['hash'] == jsonHash);

    // Update the group map
    if (songMap.isEmpty) {
      groupMap.remove(group); // If no songs left, remove the group entry
    } else {
      groupMap[group] = songMap;
    }

    // Save the updated group map back to SharedPreferences
    await prefs.setString('$_groupPrefix:group_map', jsonEncode(groupMap));

    return true;
  }

  static Future<bool> removeGroup(String group) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve all keys in the group
    final allKeysFromGroup = await getAllKeys(group);

    bool overallResult = true;

    // Remove each item in the group
    for (var key in allKeysFromGroup) {
      bool result = await prefs.remove('$_groupPrefix$group:$key');
      overallResult = overallResult && result;
    }

    // Remove the group from the index
    final Map<String, dynamic> groupIndex =
        jsonDecode(prefs.getString('$_groupPrefix:group_map') ?? '{}');
    if (groupIndex.containsKey(group)) {
      groupIndex.remove(group);
      await prefs.setString('$_groupPrefix:group_map', jsonEncode(groupIndex));
    }

    return overallResult;
  }

  static Future<Map<String, List<Map<String, String>>>> getAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    String? groupMapString = prefs.getString('$_groupPrefix:group_map');
    if (groupMapString == null) {
      return {};
    }
    Map<String, dynamic> groupIndex = jsonDecode(groupMapString);
    Map<String, List<Map<String, String>>> result = {};
    groupIndex.forEach((key, value) {
      if (value is List) {
        List<Map<String, String>> listOfMaps = [];
        for (var item in value) {
          if (item is Map) {
            listOfMaps.add(Map<String, String>.from(
                item.map((k, v) => MapEntry(k.toString(), v.toString()))));
          }
        }
        result[key] = listOfMaps;
      }
    });

    return result;
  }

  static Future<List<String>> getAllKeys(String group) async {
    final groupMap = await getAllGroups();
    final listOfMaps = groupMap[group] ?? [];
    List<String> listOfKeys = listOfMaps.map((map) => map['hash']!).toList();

    return listOfKeys;
  }

  static Future<Map<String, Map<String, dynamic>>> loadJsonsFromGroup(
      String group) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> keys = await getAllKeys(group);
    Map<String, Map<String, dynamic>> result = {};
    for (String key in keys) {
      String? jsonString = prefs.getString('$_keyPrefix:$key');
      if (jsonString != null) {
        result[key] = jsonDecode(jsonString);
      }
    }
    return result;
  }
}
