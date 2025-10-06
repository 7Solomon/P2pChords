import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/data_base/functions.dart' as db_functions;
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/networking/auth.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

Future<void> importGroup() async {
  // Pick a file
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'], // Only allow JSON files
  );

  if (result != null && result.files.single.path != null) {
    String filePath = result.files.single.path!;
    String fileContent = await File(filePath).readAsString();

    Map<String, dynamic> jsonData = jsonDecode(fileContent);

    SongData songData = SongData.fromMap(jsonData);

    for (var data in songData.groups.entries) {
      await MultiJsonStorage.saveNewGroup(data.key);
      for (String hash in data.value) {
        await MultiJsonStorage.saveJson(songData.songs[hash]!, group: data.key);
      }
    }
  }
}

Future<void> createNewGroupDialog(BuildContext context) async {
  final TextEditingController controller = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Erstelle eine neue Gruppe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Gruppen Name'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Erstellen'),
            onPressed: () async {
              String newGroup = controller.text.trim();
              if (newGroup.isNotEmpty) {
                //await MultiJsonStorage.saveNewGroup(newGroup);
                Provider.of<DataLoadeProvider>(context, listen: false)
                    .addGroup(newGroup);

                SnackService().showSuccess(
                  'Gruppe "$newGroup" erstellt',
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}

Future<bool> exportGroupsData(SongData songsData) async {
  // In exportGroupsData function
  String groups = songsData.groups.keys.join('-');
  String groupHash =
      sha256.convert(utf8.encode(groups)).toString().substring(0, 8);
  try {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    String filePath =
        '${downloadsDirectory!.path}/${groupHash}_p2pController.json';

    // Convert the Map to a JSON string
    String jsonString = jsonEncode(songsData.toMap());

    // Write the JSON string to the file
    File file = File(filePath);
    await file.writeAsString(jsonString);

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> downloadSong(Song song) async {
  //String songHash = song.hash;
  try {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    String authorName;
    if (song.header.authors.isNotEmpty) {
      authorName = song.header.authors[0];
    } else {
      authorName = 'unknown';
    }
    String filePath =
        '${downloadsDirectory!.path}/${song.header.name}_$authorName.json';

    // Convert the Map to a JSON string
    String jsonString = jsonEncode(song.toMap());

    // Write the JSON string to the file
    File file = File(filePath);
    await file.writeAsString(jsonString);

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> sendToServer(Song song, {BuildContext? context}) async {
  final tokenManager = ApiTokenManager();
  
  // Get saved server IPs
  final savedIps = await tokenManager.getSavedServerIps();
  
  if (savedIps.isEmpty) {
    SnackService().showError(
      'Keine Server gespeichert. Bitte zuerst einen Server hinzufügen.',
    );
    return false;
  }

  // If context is provided, show dialog to select server and subfolder
  String? selectedServer;
  String? subfolder;

  if (context != null && context.mounted) {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ServerUploadDialog(
          savedServers: savedIps,
          song: song,
        );
      },
    );

    if (result == null) {
      // User cancelled
      return false;
    }

    selectedServer = result['server'];
    subfolder = result['subfolder'];
  } else {
    // No context, use first saved server
    selectedServer = savedIps.first;
  }

  if (selectedServer == null) {
    return false;
  }

  SnackService().showInfo(
    'Sende "${song.header.name}" auf den Server...',
  );

  try {
    final success = await db_functions.uploadSongToServer(
      serverUrl: selectedServer,
      song: song,
      subfolder: subfolder,
    );

    return success;
  } catch (e) {
    SnackService().showError(
      'Fehler beim Senden: $e',
    );
    return false;
  }
}

// Dialog for server and subfolder selection
class _ServerUploadDialog extends StatefulWidget {
  final List<String> savedServers;
  final Song song;

  const _ServerUploadDialog({
    required this.savedServers,
    required this.song,
  });

  @override
  State<_ServerUploadDialog> createState() => _ServerUploadDialogState();
}

class _ServerUploadDialogState extends State<_ServerUploadDialog> {
  String? _selectedServer;
  String? _selectedSubfolder;
  List<String>? _availableSubfolders;
  bool _isLoadingFolders = false;
  final TextEditingController _newFolderController = TextEditingController();
  bool _createNewFolder = false;

  @override
  void initState() {
    super.initState();
    _selectedServer = widget.savedServers.first;
    _loadSubfolders();
  }

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  Future<void> _loadSubfolders() async {
    if (_selectedServer == null) return;
    
    setState(() => _isLoadingFolders = true);
    
    try {
      final folders = await db_functions.getServerSubfolders(
        serverUrl: _selectedServer!,
      );
      
      if (mounted) {
        setState(() {
          _availableSubfolders = folders;
          _isLoadingFolders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableSubfolders = [];
          _isLoadingFolders = false;
        });
        SnackService().showError('Fehler beim Laden der Ordner: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.blue),
          SizedBox(width: 12),
          Text('Auf Server hochladen'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Song: ${widget.song.header.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Server selection
            const Text('Server:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedServer,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.savedServers.map((server) {
                return DropdownMenuItem(
                  value: server,
                  child: Text(server, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServer = value;
                  _availableSubfolders = null;
                  _selectedSubfolder = null;
                });
                _loadSubfolders();
              },
            ),

            const SizedBox(height: 16),

            // Subfolder selection
            const Text('Ordner (optional):', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            if (_isLoadingFolders)
              const Center(child: CircularProgressIndicator())
            else if (_availableSubfolders != null && _availableSubfolders!.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _selectedSubfolder,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Root (kein Ordner)'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Root (kein Ordner)'),
                  ),
                  ..._availableSubfolders!.map((folder) {
                    return DropdownMenuItem(
                      value: folder,
                      child: Text(folder),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSubfolder = value;
                    _createNewFolder = false;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.create_new_folder, size: 18),
                label: const Text('Neuen Ordner erstellen'),
                onPressed: () {
                  setState(() => _createNewFolder = !_createNewFolder);
                },
              ),
            ] else
              TextButton.icon(
                icon: const Icon(Icons.create_new_folder, size: 18),
                label: const Text('Neuen Ordner erstellen'),
                onPressed: () {
                  setState(() => _createNewFolder = !_createNewFolder);
                },
              ),

            if (_createNewFolder) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _newFolderController,
                decoration: InputDecoration(
                  labelText: 'Neuer Ordnername',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedSubfolder = value.trim().isEmpty ? null : value.trim();
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            final subfolder = _createNewFolder 
                ? _newFolderController.text.trim()
                : _selectedSubfolder;
            
            Navigator.of(context).pop({
              'server': _selectedServer,
              'subfolder': subfolder?.isEmpty == true ? null : subfolder,
            });
          },
          child: const Text('Hochladen'),
        ),
      ],
    );
  }
}

Future<void> exportSong(BuildContext context, Song song) async {
  // In exportGroupsData function
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportiere den Song'),
          content: const Text('Was willst du mit dem Song machen?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Downloaden'),
              onPressed: () async {
                bool success = await downloadSong(song);
                if (success) {
                  SnackService().showSuccess(
                    'Song "${song.header.name}" exportiert!',
                  );
                } else {
                  SnackService().showError(
                    'Fehler beim Exportieren des Songs.',
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Auf einen Server senden'),
              onPressed: () async {
                bool success = await sendToServer(song);
                if (success) {
                  SnackService().showSuccess(
                    'Song "${song.header.name}" auf den Server gesendet!',
                  );
                } else {
                  SnackService().showError(
                    'Fehler beim Senden des Songs auf den Server.',
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}

Future<void> showDeleteConfirmationDialog(
    BuildContext context, String group, VoidCallback onDeleteConfirmed) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Bestätige das Löschen'),
        content: const Text(
            'Bist du sicher, dass du die Gruppe permanent löschen willst? Das kann nicht mehr rückgängig gemacht werden.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              onDeleteConfirmed(); // Call the deletion callback
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Löschen'),
          ),
        ],
      );
    },
  );
}
