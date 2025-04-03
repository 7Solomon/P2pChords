import 'package:P2pChords/UiSettings/ui_styles.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
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
  final Function(int) onSectionCountChanged;

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
    required this.onSectionCountChanged,
  });

  @override
  State<SongSheetWithControls> createState() => _SongSheetWithControlsState();
}

class _SongSheetWithControlsState extends State<SongSheetWithControls> {
  double _fontSize = 16.0;
  int _sectionCount = 2;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.startFontSize;
    _sectionCount = widget.startSectionCount;
  }

  Widget _buildFooter() {
    return Container(
      decoration: UiStyles.controlsCardDecoration,
      padding: UiStyles.standardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ControlsRow(
            label: 'Text Size',
            value: _fontSize.toStringAsFixed(1),
            onDecrease: () {
              setState(() {
                _fontSize = (_fontSize - 1).clamp(12.0, 24.0);
                widget.onFontSizeChanged(_fontSize);
              });
            },
            onIncrease: () {
              setState(() {
                _fontSize = (_fontSize + 1).clamp(12.0, 24.0);
                widget.onFontSizeChanged(_fontSize);
              });
            },
          ),
          const SizedBox(height: 8.0),
          ControlsRow(
            label: 'Section Count',
            value: _sectionCount.toString(),
            onDecrease: () {
              setState(() {
                _sectionCount = (_sectionCount - 1).clamp(1, 5);
                widget.onSectionCountChanged(_sectionCount);
              });
            },
            onIncrease: () {
              setState(() {
                _sectionCount = (_sectionCount + 1).clamp(1, 5);
                widget.onSectionCountChanged(_sectionCount);
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
            key: ValueKey('${_fontSize}_$_sectionCount'),
            songs: widget.songs,
            songIndex: widget.songIndex,
            sectionIndex: widget.sectionIndex,
            currentKey: widget.currentKey,
            startSectionCount: _sectionCount,
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
