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
  final double startMinColumnWidth;
  final int startSectionCount;
  final Function(int) onSectionChanged;
  final Function(int) onSongChanged;
  final Function(double) onFontSizeChanged;
  final Function(double) onMinColumnWidthChanged;
  final Function(int) onSectionCountChanged;

  const SongSheetWithControls({
    super.key,
    required this.songs,
    required this.songIndex,
    required this.sectionIndex,
    required this.currentKey,
    required this.startFontSize,
    required this.startMinColumnWidth,
    required this.startSectionCount,
    required this.onSectionChanged,
    required this.onSongChanged,
    required this.onFontSizeChanged,
    required this.onMinColumnWidthChanged,
    required this.onSectionCountChanged,
  });

  @override
  State<SongSheetWithControls> createState() => _SongSheetWithControlsState();
}

class _SongSheetWithControlsState extends State<SongSheetWithControls> {
  late double _fontSize;
  late double _minColumnWidth;
  late int _sectionCount;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.startFontSize;
    _sectionCount = widget.startSectionCount;
    _minColumnWidth = widget.startMinColumnWidth;
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
          const SizedBox(height: 8.0),
          ControlsRow(
            label: 'Minimum Column Width',
            value: _minColumnWidth.toString(),
            onDecrease: () {
              setState(() {
                _minColumnWidth = (_minColumnWidth - 10).clamp(100, 600);
                widget.onMinColumnWidthChanged(_minColumnWidth);
              });
            },
            onIncrease: () {
              setState(() {
                _minColumnWidth = (_minColumnWidth + 10).clamp(100, 600);
                widget.onMinColumnWidthChanged(_minColumnWidth);
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
            startMinColumnWidth: _minColumnWidth,
            onSectionChanged: widget.onSectionChanged,
            onSongChanged: widget.onSongChanged,
          ),
        ),
        _buildFooter(),
      ],
    );
  }
}
