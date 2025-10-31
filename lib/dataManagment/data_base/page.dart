import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/data_base/server_selection_dialog.dart';
import 'package:flutter/material.dart';
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
  List<Song>? _filteredSongs;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_importedSongs == null) return;

    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = _importedSongs;
      });
      return;
    }

    setState(() {
          _filteredSongs = _importedSongs!.where((song) {
            final titleMatch = song.header.name.toLowerCase().contains(query);
            final artistMatch = (song.header.authors)
                .any((author) => author.toLowerCase().contains(query));
            return titleMatch || artistMatch;
          }).toList();
        });
  }

  Future<void> _importSongData() async {
    final serverUrl = await showServerSelectionDialog(context);

    if (serverUrl == null || serverUrl.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _hasError = false;
      _importedSongs = null;
      _filteredSongs = null;
      _searchController.clear();
    });

    try {
      final List<Song>? songs = await fetchSongDataFromServer(
        serverUrl: serverUrl,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (songs != null && songs.isNotEmpty) {
          _importedSongs = songs;
          _filteredSongs = songs;
          _statusMessage = '${songs.length} Songs gefunden';
          _hasError = false;
        } else {
          _statusMessage = 'Keine Songs gefunden';
          _hasError = true;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = 'Verbindungsfehler';
        _hasError = true;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredSongs = _importedSongs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Song oder Künstler suchen...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              )
            : const Text(
                'Song Datenbank',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
        leading: IconButton(
          icon: Icon(
            _isSearching ? Icons.arrow_back : Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            if (_isSearching) {
              _toggleSearch();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: (_importedSongs?.isNotEmpty ?? false)
            ? [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.black87,
                  ),
                  onPressed: _toggleSearch,
                ),
              ]
            : null,
      ),
      body: (_importedSongs?.isNotEmpty ?? false)
          ? Column(
              children: [
                if (_filteredSongs != null && _searchController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredSongs!.length} von ${_importedSongs!.length} Songs',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredSongs!.isEmpty
                      ? _buildNoResultsState()
                      : SongListView(songs: _filteredSongs!),
                ),
              ],
            )
          : _buildEmptyState(),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Songs gefunden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versuche andere Suchbegriffe',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lade Songs...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_music_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'Song Datenbank',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Verbinde dich mit dem Server, um auf die Song-Datenbank zuzugreifen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Connect button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _importSongData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasError ? Icons.refresh : Icons.cloud_download_outlined,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _hasError ? 'Erneut versuchen' : 'Mit Server verbinden',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error message
            if (_hasError && _statusMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hinweis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alle Songs aus der Datenbank können vorgeschaut und heruntergeladen werden',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}