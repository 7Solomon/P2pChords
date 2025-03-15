import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';
import 'package:flutter/material.dart';

class SongSheetWithControls extends StatefulWidget {
  final Song song;
  final String currentKey;
  final double startFontSize;
  final Function(int) onSectionChanged;
  final Function(double) onFontSizeChanged;

  const SongSheetWithControls({
    super.key,
    required this.song,
    required this.currentKey,
    required this.startFontSize,
    required this.onSectionChanged,
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
            song: widget.song,
            currentKey: widget.currentKey,
            startFontSize: _fontSize,
            onSectionChanged: widget.onSectionChanged,
          ),
        ),
        _buildFooter(),
      ],
    );
  }
}
