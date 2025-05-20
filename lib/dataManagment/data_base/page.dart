import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'functions.dart';
import 'song_list_view.dart';

class ServerImportPage extends StatefulWidget {
  const ServerImportPage({Key? key}) : super(key: key);

  @override
  _ServerImportPageState createState() => _ServerImportPageState();
}

class _ServerImportPageState extends State<ServerImportPage> {
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  List<Song>? _importedSongs;

  // Keys for shared preferences
  static const String _serverUrlKey = 'saved_song_server_url';

  @override
  void initState() {
    super.initState();
    _loadSavedServerUrl();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  // Load previously saved server URL from device storage
  Future<void> _loadSavedServerUrl() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedServerUrl = prefs.getString(_serverUrlKey);

      if (savedServerUrl != null && savedServerUrl.isNotEmpty) {
        setState(() {
          _serverUrlController.text = savedServerUrl;
        });
      }
    } catch (e) {
      print('Error loading saved server URL: $e');
    }
  }

  // Save server URL to device storage
  Future<void> _saveServerUrl(String serverUrl) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverUrlKey, serverUrl);
    } catch (e) {
      print('Error saving server URL: $e');
      setState(() {
        _statusMessage = 'Failed to save server URL locally: $e';
        _hasError = true;
      });
    }
  }

  // Import song data from custom server
  Future<void> _importSongData() async {
    final String serverUrl = _serverUrlController.text.trim();

    if (serverUrl.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter the server URL';
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to server and searching for song files...';
      _hasError = false;
    });

    try {
      // Save the server URL for future use
      await _saveServerUrl(serverUrl);

      // Fetch the song data from all files in the server
      final List<Song>? songs = await fetchSongDataFromServer(
        serverUrl: serverUrl,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (songs != null && songs.isNotEmpty) {
          _importedSongs = songs;
          _statusMessage =
              'Successfully imported ${songs.length} songs from server';
          _hasError = false;
        } else {
          _statusMessage = 'Failed to import song data from server';
          _hasError = true;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importiere Songs von Server'),
      ),
      body: (_importedSongs?.isNotEmpty ?? false)
          ? SongListView(
              songs: _importedSongs!,
            )
          : _buildImportForm(),
    );
  }

  Widget _buildImportForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bedienung:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hier URL zu einem Server eingeben, der JSON-Dateien mit Songdaten bereitstellt.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Der server muss einen /list endpunt haben, der eine Liste von JSON-Dateien zurückgibt.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Server URL input
          TextField(
            controller: _serverUrlController,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'e.g., https://myserver.com:PORT',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _serverUrlController.clear();
                },
              ),
            ),
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 16),

          // Import button
          ElevatedButton(
            onPressed: _isLoading ? null : _importSongData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Importieren...'),
                    ],
                  )
                : const Text('Importiere Songs von Server'),
          ),

          const SizedBox(height: 24),

          // Status message
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasError ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _hasError ? Colors.red.shade300 : Colors.green.shade300,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color:
                      _hasError ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
