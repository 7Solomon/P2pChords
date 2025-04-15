import 'dart:math';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/grid_builder.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/section_tile.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResponsiveSongLayout extends StatelessWidget {
  final List<Song> songs;
  final int currentSectionIndex;
  final int currentSongIndex;
  //final UiVariables uiVariables;
  final Widget Function(LineData) buildLine;

  const ResponsiveSongLayout({
    super.key,
    required this.songs,
    required this.currentSectionIndex,
    required this.currentSongIndex,
    //required this.uiVariables,
    required this.buildLine,
  });

  @override
  Widget build(BuildContext context) {
    final uiVariables = Provider.of<SheetUiProvider>(context).uiVariables;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Create a key for the current section for scrolling
        final currentSectionKey = GlobalKey();

        // Collect sections to display
        final sectionsToDisplay = _collectSections(uiVariables);

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
            child: CGridViewBuild(
              currentSectionIndex: currentSectionIndex,
              currentSongIndex: currentSongIndex,
              sectionsToDisplay: sectionsToDisplay,
              buildLine: buildLine,
            ));
      },
    );
  }

  List<SectionTile> _collectSections(UiVariables uiVariables) {
    final List<SectionTile> sectionTiles = [];
    final int maxSections = uiVariables.sectionCount.value;

    // Safety checks
    if (songs.isEmpty ||
        currentSongIndex < 0 ||
        currentSongIndex >= songs.length) {
      return sectionTiles;
    }

    Song currentSong = songs[currentSongIndex];
    if (currentSectionIndex < 0 ||
        currentSectionIndex >= currentSong.sections.length) {
      return sectionTiles;
    }

    // Determine the position of current section in the visible window
    int currentPosition = 0; // Default: current section at top

    // Calculate sections before current that should be visible
    int totalSectionsBefore = 0;
    for (int s = 0; s < currentSongIndex; s++) {
      totalSectionsBefore += songs[s].sections.length;
    }
    totalSectionsBefore += currentSectionIndex;

    // Calculate total sections in all songs
    int totalSections = 0;
    for (int s = 0; s < songs.length; s++) {
      totalSections += songs[s].sections.length;
    }

    // Calculate sections after current
    int totalSectionsAfter = totalSections - totalSectionsBefore - 1;

    // Adjust position based on navigation context
    if (totalSectionsBefore < maxSections - 1) {
      // Near the beginning - keep current at beginning
      currentPosition = totalSectionsBefore;
    } else if (totalSectionsAfter < maxSections - 1) {
      // Near the end - position current section to show all remaining
      currentPosition = maxSections - totalSectionsAfter - 1;
    } else {
      // Middle region - ensure we can always see the current section
      currentPosition = min(1, maxSections - 1);
      // Removed the dangling expression
    }

    // Start from the current section
    int songIdx = currentSongIndex;
    int sectionIdx = currentSectionIndex;

    // Navigate backward to find start position
    // But make sure we don't go past the beginning
    int stepsBack = min(currentPosition, totalSectionsBefore);
    for (int i = 0; i < stepsBack; i++) {
      sectionIdx--;
      if (sectionIdx < 0) {
        songIdx--;
        if (songIdx < 0) break; // Should never happen with the min check above
        sectionIdx = songs[songIdx].sections.length - 1;
        // Skip empty songs
        while (songIdx >= 0 && songs[songIdx].sections.isEmpty) {
          songIdx--;
          if (songIdx < 0) break;
          sectionIdx = songs[songIdx].sections.length - 1;
        }
        if (songIdx < 0) break;
      }
    }

    // If we couldn't go back enough steps, we're at the beginning
    // Now collect maxSections sections starting from this position
    for (int count = 0; count < maxSections; count++) {
      if (songIdx < 0 || songIdx >= songs.length) break;

      // Handle edge case of empty sections
      if (songs[songIdx].sections.isEmpty) {
        songIdx++;
        count--; // Don't count empty songs
        continue;
      }

      // Handle moving to next song if needed
      if (sectionIdx >= songs[songIdx].sections.length) {
        songIdx++;
        if (songIdx >= songs.length) break;
        sectionIdx = 0;
        // Skip empty songs going forward
        while (songIdx < songs.length && songs[songIdx].sections.isEmpty) {
          songIdx++;
          if (songIdx >= songs.length) break;
        }
        if (songIdx >= songs.length) break;
        continue; // Recheck current loop iteration with new indices
      }

      bool isCurrentSection =
          (songIdx == currentSongIndex && sectionIdx == currentSectionIndex);

      sectionTiles.add(
        SectionTile(
          song: songs[songIdx],
          section: songs[songIdx].sections[sectionIdx],
          songIndex: songIdx,
          sectionIndex: sectionIdx,
          isFirstSectionOfSong: sectionIdx == 0,
          isLastSectionOfSong: sectionIdx == songs[songIdx].sections.length - 1,
          isCurrentSection: isCurrentSection,
          isCurrentSong: songIdx == currentSongIndex,
          buildLine: buildLine,
        ),
      );

      // Move to next section
      sectionIdx++;
    }

    return sectionTiles;
  }
}
