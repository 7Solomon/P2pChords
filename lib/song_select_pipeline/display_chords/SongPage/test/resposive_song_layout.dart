import 'dart:math';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/helper.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/test/section_tile.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/test/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ResponsiveSongLayout extends StatelessWidget {
  final List<Song> songs;
  final int currentSectionIndex;
  final int currentSongIndex;
  final UiVariables uiVariables;
  final Widget Function(LyricLine) buildLine;

  const ResponsiveSongLayout({
    super.key,
    required this.songs,
    required this.currentSectionIndex,
    required this.currentSongIndex,
    required this.uiVariables,
    required this.buildLine,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many columns we can fit based on available width
        final availableWidth = constraints.maxWidth - 32; // Account for padding
        final columnWidth = uiVariables.columnWidth.value;
        final columnSpacing = uiVariables.columnSpacing.value;

        // Calculate max columns that fit
        final crossAxisCount = max(
            1,
            ((availableWidth + columnSpacing) / (columnWidth + columnSpacing))
                .floor());

        // Create a key for the current section for scrolling
        final currentSectionKey = GlobalKey();

        // Collect sections to display
        final sectionsToDisplay = _collectSections();

        // Safety check
        if (sectionsToDisplay.isEmpty) {
          return const Center(child: Text("No sections to display"));
        }

        // Add post-frame callback to scroll to current section
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentSectionKey.currentContext != null) {
            Scrollable.ensureVisible(
              currentSectionKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              alignment: 0.0,
            );
          }
        });

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: MasonryGridView.count(
            shrinkWrap: true, // Add this
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: uiVariables.rowSpacing.value,
            crossAxisSpacing: columnSpacing,
            physics: const TapFriendlyScrollPhysics(),
            itemCount: sectionsToDisplay.length,
            itemBuilder: (context, index) {
              if (index >= sectionsToDisplay.length) {
                return const SizedBox.shrink(); // Safety check
              }

              final SectionInfo sectionData = sectionsToDisplay[index];
              final bool isCurrentSection =
                  sectionData.songIndex == currentSongIndex &&
                      sectionData.sectionIndex == currentSectionIndex;

              return SectionTile(
                key: isCurrentSection ? currentSectionKey : null,
                song: sectionData.song,
                section: sectionData.section,
                songIndex: sectionData.songIndex,
                sectionIndex: sectionData.sectionIndex,
                isCurrentSection: isCurrentSection,
                isCurrentSong: sectionData.songIndex == currentSongIndex,
                isFirstSectionOfSong: sectionData.isFirstSectionOfSong,
                isLastSectionOfSong: sectionData.isLastSectionOfSong,
                uiVariables: uiVariables,
                buildLine: buildLine,
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to collect sections to display (no changes needed here)
  List<SectionInfo> _collectSections() {
    // Existing implementation
    final List<SectionInfo> sectionsToDisplay = [];
    final maxSections = uiVariables.sectionCount.value;
    int totalSectionCount = 0;
    int songIdx = currentSongIndex;
    int? prevSongIndex;

    // Collect all sections we want to display
    while (songIdx < songs.length && totalSectionCount < maxSections) {
      if (songIdx < 0 || songIdx >= songs.length) break; // Safety check

      var song = songs[songIdx];
      bool isCurrentSong = songIdx == currentSongIndex;
      bool isNewSong = prevSongIndex != songIdx;
      prevSongIndex = songIdx;

      if (song.sections.isEmpty) {
        songIdx++;
        continue;
      }

      int startSectionIdx = (isCurrentSong) ? currentSectionIndex : 0;
      if (startSectionIdx < 0) startSectionIdx = 0; // Safety check
      if (startSectionIdx >= song.sections.length)
        startSectionIdx = 0; // Safety check

      for (int secIdx = startSectionIdx;
          secIdx < song.sections.length && totalSectionCount < maxSections;
          secIdx++) {
        var section = song.sections[secIdx];
        bool isFirstSectionOfSong = secIdx == startSectionIdx;
        bool isLastSectionOfSong = secIdx == song.sections.length - 1;

        sectionsToDisplay.add(SectionInfo(
          song: song,
          section: section,
          songIndex: songIdx,
          sectionIndex: secIdx,
          isFirstSectionOfSong: isFirstSectionOfSong,
          isLastSectionOfSong: isLastSectionOfSong,
        ));

        totalSectionCount++;
      }

      songIdx++;
    }

    return sectionsToDisplay;
  }
}
