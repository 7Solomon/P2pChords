import 'package:shared_preferences/shared_preferences.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';

class DataLoader {
  Map<String, dynamic>? _groups;
  Map<String, dynamic>? _songs;

  // Constructor that initializes and loads data
  DataLoader() {
    _loadDataFromStorage();
  }

  // Function to load data from SharedPreferences
  Future<void> _loadDataFromStorage() async {
    await MultiJsonStorage.getAllGroups().then((value) {
      _groups = value;
    });
    for (String groupName in _groups!.keys) {
      await MultiJsonStorage.getAllKeys(groupName).then((value) async {
        for (String songHash in value) {
          await MultiJsonStorage.loadJson(songHash).then((value) {
            _songs![songHash] = value;
          });
        }
      });
    }
  }

  Future<void> refreshData() async {
    await _loadDataFromStorage();
  }

  Map<String, dynamic>? get data => _groups;
  Map<String, dynamic>? get songs => _songs;
}
