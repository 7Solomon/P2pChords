import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/line_builds.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/section_view.dart';
//import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/helper.dart';
import 'package:flutter/material.dart';

class _LineSegment {
  final String text;
  final List<Chord> chords;
  final int startIndex;

  _LineSegment(this.text, this.chords, this.startIndex);
}

class SongSheetDisplay extends StatefulWidget {
  final List<Song> songs;
  final int songIndex;
  final int sectionIndex;
  final String currentKey;
  //final UiVariables uiVariables;
  final Function(int) onSectionChanged;
  final Function(int) onSongChanged;
  final Function(BuildContext, TapDownDetails)? onTapDown;

  const SongSheetDisplay({
    super.key,
    required this.songs,
    required this.songIndex,
    required this.sectionIndex,
    required this.currentKey,
    //required this.uiVariables,
    required this.onSectionChanged,
    required this.onSongChanged,
    this.onTapDown,
  });

  @override
  State<SongSheetDisplay> createState() => _SongSheetDisplayState();
}

class _SongSheetDisplayState extends State<SongSheetDisplay> {
  late int _currentSectionIndex;
  late int _currentSongIndex;
  //
  late LineBuildFunction _sectionBuilder;

  Song get currentSong => widget.songs[_currentSongIndex];
  int get currentSectionLength => currentSong.sections.length;
  Song? get songAfter {
    if (_currentSongIndex >= 0 && _currentSongIndex < widget.songs.length - 1) {
      return widget.songs[_currentSongIndex + 1];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentSectionIndex = widget.sectionIndex;
    _currentSongIndex = widget.songIndex;

    // Line builder function
    _sectionBuilder = LineBuildFunction(context, widget.currentKey);
  }

  @override
  void didUpdateWidget(SongSheetDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for section changes
    if (widget.sectionIndex != _currentSectionIndex) {
      setState(() {
        _currentSectionIndex = widget.sectionIndex;
      });
    }

    // Check for song changes
    if (oldWidget.songIndex != widget.songIndex ||
        oldWidget.songs != widget.songs) {
      _currentSongIndex = widget.songIndex;
    }

    // For LineBuilderFunction, check if the current key or uiVariables have changed, changed to just key
    if (oldWidget.currentKey != widget.currentKey) {
      _sectionBuilder = LineBuildFunction(context, widget.currentKey);
    }
  }

  void navigateToPreviousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
        widget.onSectionChanged(_currentSectionIndex);
      });
    } else if (_currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
        // Fix where empty sections were a problem
        _currentSectionIndex = widget.songs[_currentSongIndex].sections.isEmpty
            ? 0
            : widget.songs[_currentSongIndex].sections.length - 1;
        widget.onSongChanged(_currentSongIndex);
      });
    }
  }

  void navigateToNextSection() {
    if (_currentSectionIndex < currentSectionLength - 1) {
      setState(() {
        _currentSectionIndex++;
        widget.onSectionChanged(_currentSectionIndex);
      });
    } else if (_currentSongIndex < widget.songs.length - 1) {
      setState(() {
        _currentSongIndex++;
        _currentSectionIndex = 0;
        widget.onSongChanged(_currentSongIndex);
      });
    }
  }

  // Handle the tap event
  void handleScreenTap(BuildContext context, TapDownDetails details) {
    if (widget.onTapDown != null) {
      widget.onTapDown!(context, details);
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final tapPositionY = details.globalPosition.dy;
    if (tapPositionY < screenHeight / 2) {
      navigateToPreviousSection();
    } else {
      navigateToNextSection();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SectionView(
            songs: widget.songs,
            currentSectionIndex: _currentSectionIndex,
            currentSongIndex: _currentSongIndex,
            buildLineFunction: _sectionBuilder.buildLine,
            onTapDown: (context, details) => handleScreenTap(context, details),
          ),
        ),
      ],
    );
  }
}
