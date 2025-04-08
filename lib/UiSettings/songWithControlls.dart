import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/UiSettings/footer.dart';
import 'package:P2pChords/UiSettings/ui_styles.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet.dart';
import 'package:flutter/material.dart';

class SongSheetWithControls extends StatefulWidget {
  final List<Song> songs;
  final int songIndex;
  final int sectionIndex;
  final String currentKey;
  final Function(int) onSectionChanged;
  final Function(int) onSongChanged;
  final Function(UiVariables) onUiVariablesChanged;
  UiVariables uiVariables;

  SongSheetWithControls(
      {super.key,
      required this.songs,
      required this.songIndex,
      required this.sectionIndex,
      required this.currentKey,
      required this.uiVariables,
      required this.onSectionChanged,
      required this.onSongChanged,
      required this.onUiVariablesChanged});

  @override
  State<SongSheetWithControls> createState() => _SongSheetWithControlsState();
}

class _SongSheetWithControlsState extends State<SongSheetWithControls> {
  final ValueNotifier<bool> _showAllControls = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _showAllControls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content
        SongSheetDisplay(
          songs: widget.songs,
          songIndex: widget.songIndex,
          sectionIndex: widget.sectionIndex,
          currentKey: widget.currentKey,
          uiVariables: widget.uiVariables,
          onSectionChanged: widget.onSectionChanged,
          onSongChanged: widget.onSongChanged,
        ),

        SongControlsFooter(
          showControlsNotifier: _showAllControls,
          uiVariables: widget.uiVariables,
          onUiVariablesChanged: widget.onUiVariablesChanged,
          onCloseTap: () {
            _showAllControls.value = false;
          },
        ),
      ],
    );
  }
}
