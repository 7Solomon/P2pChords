import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
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
    setState(() => _isSaving = true);

    try {
      final song = widget.songs[_currentSongIndex];
      final dataProvider =
          Provider.of<DataLoadeProvider>(context, listen: false);
      
      dataProvider.addSong(song);

      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${song.header.name} wurde gespeichert',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Fehler beim Speichern')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[_currentSongIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentSong.header.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              currentSong.header.authors.join(', '),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, color: Colors.black87),
            onPressed: _isSaving ? null : () => _saveSong(context),
          ),
        ],
      ),
      body: SongSheetDisplay(
        songs: [currentSong],
        songIndex: 0,
        sectionIndex: _currentSectionIndex,
        currentKey: currentSong.header.key,
        onSectionChanged: _onSectionChanged,
        onSongChanged: _onSongChanged,
      ),
    );
  }
}