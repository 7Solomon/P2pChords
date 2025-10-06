import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

class DataLoadeProvider extends ChangeNotifier {
  Map<String, List<String>>? _groups;
  Map<String, Song>? _songs;
  bool isLoading = false;
  bool _initialized = false;

  // Provide safer access methods
  Map<String, List<String>> get groups => _groups ?? {};
  Map<String, Song> get songs => _songs ?? {};
  bool get isInitialized => _initialized;

  // Constructor that initializes and loads data
  DataLoadeProvider() {
    initializeData();
  }

  // Initialize with a clear state
  Future<void> initializeData() async {
    await _loadDataFromStorage();
  }

  // Function to load data from SharedPreferences
  Future<void> _loadDataFromStorage() async {
    isLoading = true;
    notifyListeners();

    try {
      SongData groupsData = await MultiJsonStorage.getSavedSongsData();
      _groups = groupsData.groups;
      _songs = groupsData.songs;
      _initialized = true;
    } catch (e) {
      _groups = {};
      _songs = {};
      debugPrint('Error loading data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Add Song to the provider and storage
  Future<bool> addSong(Song song, {String? groupName}) async {
    _songs ??= {};
    _groups ??= {};

    _songs![song.hash] = song;

    // Only add to a group if groupName is provided
    if (groupName != null) {
      _groups!.putIfAbsent(groupName, () => []);
      if (!_groups![groupName]!.contains(song.hash)) {
        _groups![groupName]!.add(song.hash);
      }
    }
    notifyListeners();
    return await MultiJsonStorage.saveJson(song, group: groupName);
  }

  Future<bool> addGroup(String groupName) async {
    if (_groups == null) return false;

    // Check if the group already exists
    if (!_groups!.containsKey(groupName)) {
      _groups![groupName] = [];
      await MultiJsonStorage.saveNewGroup(groupName);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addSongToGroup(String groupName, String hash) async {
    if (_groups == null || _songs == null) return false;

    // Check if the group exists
    if (!_groups!.containsKey(groupName)) {
      _groups![groupName] = [];
    }

    // Add the song to the group if it doesn't already exist
    if (!_groups![groupName]!.contains(hash)) {
      _groups![groupName]!.add(hash);
      await MultiJsonStorage.addSongToGroup(groupName, hash);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeSong(String hash) async {
    if (_songs == null || !_songs!.containsKey(hash)) return false;

    _songs!.remove(hash);

    // Remove all references to this song from groups
    if (_groups != null) {
      for (final groupName in _groups!.keys) {
        if (_groups![groupName]?.contains(hash) == true) {
          await MultiJsonStorage.removeJsonFromGroup(groupName, hash);
          _groups![groupName]?.remove(hash);
        }
      }
    }
    notifyListeners();

    // Remove the actual song data
    _songs!.remove(hash);
    await MultiJsonStorage.removeJson(hash);
    return true;
  }

  Future<bool> removeGroup(String groupName) async {
    if (_groups == null || !_groups!.containsKey(groupName)) return false;

    MultiJsonStorage.removeGroup(groupName);
    _groups!.remove(groupName);
    notifyListeners();
    return true;
  }

  Future<bool> removeSongFromGroup(String groupName, String hash) async {
    if (_groups == null || !_groups!.containsKey(groupName)) return false;

    // Remove hash from the specified group in storage first
    await MultiJsonStorage.removeJsonFromGroup(groupName, hash);

    // Then update in-memory state
    _groups![groupName]?.remove(hash);

    // If the group is empty now, remove it
    if (_groups![groupName]?.isEmpty == true) {
      _groups!.remove(groupName);
    }

    notifyListeners();
    return true;
  }

  Future<bool> addSongsData(SongData songdata) async {
    _songs ??= {};
    _groups ??= {};

    for (var group in songdata.groups.entries) {
      _groups!.putIfAbsent(group.key, () => []);
      for (String hash in group.value) {
        if (!_groups![group.key]!.contains(hash)) {
          _groups![group.key]!.add(hash);
        }
        _songs![hash] = songdata.songs[hash]!;
      }
    }
    MultiJsonStorage.saveSongsData(songdata);
    notifyListeners();
    return true;
  }

  Future<void> syncToStorage() async {
    try {
      if (_songs != null && _groups != null) {
        final songData = SongData.fromDataProvider(_groups!, _songs!);
        print('Saving data to storage...');
        await MultiJsonStorage.saveSongsData(songData);
      }
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  Song? getSongByHash(String hash) {
    return _songs?[hash];
  }

  int getSongIndex(String group, String hash) {
    if (_groups == null || !_groups!.containsKey(group)) return -1;
    return _groups![group]?.indexOf(hash) ?? -1;
  }

  String? getHashByIndex(String group, int index) {
    if (_groups == null || !_groups!.containsKey(group)) return null;
    final groupSongs = _groups![group]!;
    if (index < 0 || index >= groupSongs.length) return null;
    return groupSongs[index];
  }

  List<Song> getSongsInGroup(String group) {
    List<String> songHashes = _groups?[group] ?? [];
    List<Song> result = [];

    for (var hash in songHashes) {
      final song = _songs?[hash];
      if (song != null) {
        result.add(song);
      }
    }

    return result;
  }

  String? getGroupOfSong(String hash) {
    if (_groups == null) return null;

    for (var group in _groups!.keys) {
      if (_groups![group]?.contains(hash) == true) {
        return group;
      }
    }
    return null;
  }

  SongData getSongData(String group) {
    List<Song> songs = getSongsInGroup(group);
    Map<String, List<String>> groups = Map<String, List<String>>.from(
        {group: songs.map((e) => e.hash).toList()});
    return SongData.fromDataProvider(groups, _songs!);
  }

  Future<void> reorderSongInGroup(String groupName, int oldIndex, int newIndex) async {
    if (_groups == null || !_groups!.containsKey(groupName)) return;
    
    final groupSongs = _groups![groupName]!;
    if (oldIndex < 0 || oldIndex >= groupSongs.length || 
        newIndex < 0 || newIndex >= groupSongs.length) {
      return;
    }
    
    // Reorder in memory
    final songHash = groupSongs.removeAt(oldIndex);
    groupSongs.insert(newIndex, songHash);
    
    // Save to storage
    await MultiJsonStorage.updateGroupOrder(groupName, groupSongs);
    
    notifyListeners();
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    if (_groups == null) return;
    
    final groupNames = _groups!.keys.toList();
    if (oldIndex < 0 || oldIndex >= groupNames.length || 
        newIndex < 0 || newIndex >= groupNames.length) {
      return;
    }
    
    // Reorder the keys
    final groupName = groupNames.removeAt(oldIndex);
    groupNames.insert(newIndex, groupName);
    
    // Rebuild the map in the new order
    final reorderedGroups = <String, List<String>>{};
    for (var name in groupNames) {
      reorderedGroups[name] = _groups![name]!;
    }
    
    _groups = reorderedGroups;
    
    // Save the new order to storage
    await MultiJsonStorage.saveGroupOrder(groupNames);
    
    notifyListeners();
  }
}
