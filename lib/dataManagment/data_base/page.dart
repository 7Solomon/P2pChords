import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/data_base/server_selection_dialog.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'functions.dart';
import 'song_list_view.dart';

class ServerImportPage extends StatefulWidget {
  const ServerImportPage({Key? key}) : super(key: key);

  @override
  _ServerImportPageState createState() => _ServerImportPageState();
}

class _ServerImportPageState extends State<ServerImportPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  List<Song>? _importedSongs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _importSongData() async {
    final serverUrl = await showServerSelectionDialog(context);

    if (serverUrl == null || serverUrl.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Verbinde mit Server und suche nach Song-Dateien...';
      _hasError = false;
      _importedSongs = null; // Clear previous results
    });

    try {
      // 2. Fetch the song data using the URL from the dialog
      final List<Song>? songs = await fetchSongDataFromServer(
        serverUrl: serverUrl,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (songs != null && songs.isNotEmpty) {
          _importedSongs = songs;
          _statusMessage =
              'Erfolgreich ${songs.length} Songs vom Server importiert';
          _hasError = false;
        } else {
          _statusMessage = 'Keine Songs gefunden oder Import fehlgeschlagen.';
          _hasError = true;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = 'Fehler: $e';
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
          // Instructions Card can stay the same
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
                    'Klicken Sie auf "Vom Server importieren", um eine Verbindung herzustellen. Sie können einen gespeicherten Server auswählen oder eine neue Adresse eingeben.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hinweis: Der Server muss einen /list Endpunkt haben, der eine Liste von JSON-Dateien zurückgibt.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(), // Use a spacer to push the button to the center/bottom

          // Import button is now the main action
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_download),
            label: const Text('Vom Server importieren'),
            onPressed: _isLoading ? null : _importSongData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(height: 24),

          // Status message section can stay the same
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _statusMessage.isNotEmpty)
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

          const Spacer(),
        ],
      ),
    );
  }
}
