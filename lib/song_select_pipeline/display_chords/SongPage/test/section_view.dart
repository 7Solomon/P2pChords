import 'dart:ui';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/test/resposive_song_layout.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/test/section_builds.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/test/utils.dart';
import 'package:flutter/material.dart';

class SectionView extends StatelessWidget {
  final List<Song> songs;

  final int currentSectionIndex;
  final int currentSongIndex;
  final UiVariables uiVariables;
  final Widget Function(LyricLine) buildLineFunction;
  final bool animate;
  final int? previousIndex;
  final Function(BuildContext, TapDownDetails)? onTapDown;

  const SectionView({
    super.key,
    required this.songs,
    required this.currentSectionIndex,
    required this.currentSongIndex,
    required this.uiVariables,
    required this.buildLineFunction,
    this.animate = true,
    this.previousIndex,
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    //SectionBuildFunction();

    // Build the content widget
    Widget content = ResponsiveSongLayout(
      songs: songs,
      currentSectionIndex: currentSectionIndex,
      currentSongIndex: currentSongIndex,
      uiVariables: uiVariables,
      buildLine: buildLineFunction,
    );

    // Wrap in scrollable container with tap detection
    Widget scrollableContent = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown:
          onTapDown != null ? (details) => onTapDown!(context, details) : null,
      child: SingleChildScrollView(
        physics: const TapFriendlyScrollPhysics(),
        child: content,
      ),
    );

    // Apply animation if needed
    if (!animate || previousIndex == null) {
      return scrollableContent;
    }

    // Animation logic
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool isForward = currentSectionIndex > (previousIndex ?? 0);

        final offsetAnimation = Tween<Offset>(
          begin: Offset(0.0, isForward ? -1.0 : 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentSectionIndex),
        child: scrollableContent,
      ),
    );
  }
}
