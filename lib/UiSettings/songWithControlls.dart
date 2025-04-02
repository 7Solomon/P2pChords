import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet.dart';
import 'package:flutter/material.dart';

class SongSheetWithControls extends StatefulWidget {
  final List<Song> songs;
  final int songIndex;
  final int sectionIndex;
  final String currentKey;
  final double startFontSize;
  final int startSectionCount;
  final Function(int) onSectionChanged;
  final Function(int) onSongChanged;
  final Function(double) onFontSizeChanged;

  const SongSheetWithControls({
    super.key,
    required this.songs,
    required this.songIndex,
    required this.sectionIndex,
    required this.currentKey,
    required this.startFontSize,
    required this.startSectionCount,
    required this.onSectionChanged,
    required this.onSongChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<SongSheetWithControls> createState() => _SongSheetWithControlsState();
}

class _SongSheetWithControlsState extends State<SongSheetWithControls> {
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.startFontSize;
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize - 1).clamp(12.0, 24.0);
                widget.onFontSizeChanged(_fontSize);
              });
            },
          ),
          const Flexible(
            child: Text(
              'Text Size',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize + 1).clamp(12.0, 24.0);
                widget.onFontSizeChanged(_fontSize);
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SongSheetDisplay(
            key: ValueKey(_fontSize),
            songs: widget.songs,
            songIndex: widget.songIndex,
            sectionIndex: widget.sectionIndex,
            currentKey: widget.currentKey,
            startSectionCount: widget.startSectionCount,
            startFontSize: _fontSize,
            onSectionChanged: widget.onSectionChanged,
            onSongChanged: widget.onSongChanged,
          ),
        ),
        _buildFooter(),
      ],
    );
  }
}
