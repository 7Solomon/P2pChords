import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongDetailView extends StatefulWidget {
  final List<Song> songs;
  final int initialSongIndex;

  const SongDetailView({
    super.key,
    required this.songs,
    required this.initialSongIndex,
  });

  @override
  State<SongDetailView> createState() => _SongDetailViewState();
}

class _SongDetailViewState extends State<SongDetailView> {
  late int _currentSongIndex;
  late int _currentSectionIndex;
  bool _isSaving = false;
  String _saveMessage = '';

  @override
  void initState() {
    super.initState();
    _currentSongIndex = widget.initialSongIndex;
    _currentSectionIndex = 0;
  }

  void _onSectionChanged(int newIndex) {
    setState(() {
      _currentSectionIndex = newIndex;
    });
  }

  void _onSongChanged(int newIndex) {
    setState(() {
      _currentSongIndex = newIndex;
      _currentSectionIndex = 0;
    });
  }

  Future<void> _saveSong(BuildContext context) async {
    setState(() {
      _isSaving = true;
      _saveMessage = 'Saving song...';
    });

    try {
      final song = widget.songs[_currentSongIndex];

      final dataProvider =
          Provider.of<DataLoadeProvider>(context, listen: false);
      dataProvider.addSong(song);
      setState(() {
        _isSaving = false;
        _saveMessage = 'Song "${song.header.name}" Gespeichert!';
      });

      // Clear the message after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _saveMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveMessage = 'Error saving song: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[_currentSongIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong.header.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving
                  ? null
                  : () {
                      _saveSong(context);
                    }),
        ],
      ),
      body: Stack(
        children: [
          // Song display
          SongSheetDisplay(
            songs: [currentSong],
            songIndex: _currentSongIndex,
            sectionIndex: _currentSectionIndex,
            currentKey: currentSong.header.key,
            onSectionChanged: _onSectionChanged,
            onSongChanged: _onSongChanged,
          ),

          // Save message
          if (_saveMessage.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _saveMessage.contains('Error')
                      ? Colors.red.withOpacity(0.9)
                      : Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _saveMessage.contains('Error')
                          ? Icons.error
                          : Icons.check_circle,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _saveMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
