import 'dart:math';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/sheet_ui_provider.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/grid_builder.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/section_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResponsiveLayout extends StatelessWidget {
  final List<Song> songs;
  final int currentSectionIndex;
  final int currentSongIndex;
  //final UiVariables uiVariables;
  final Widget Function(LineData) buildLine;

  const ResponsiveLayout({
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
        // Collect sections to display
        final sectionsToDisplay = _collectSections(uiVariables);

        // Safety check
        if (sectionsToDisplay.isEmpty) {
          return const Center(child: Text("No sections to display"));
        }

        // Horizontal layout

        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: CGridViewBuild(
              currentSectionIndex: currentSectionIndex,
              currentSongIndex: currentSongIndex,
              sectionsToDisplay: sectionsToDisplay,
              buildLine: buildLine,
            ));

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 1 / 1.2,
            ),
            itemCount: sectionsToDisplay.length,
            itemBuilder: (context, index) {
              return sectionsToDisplay[index];
            },
          ),
        );
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
      print('safty not insurred on songs');
      return sectionTiles;
    }

    Song currentSong = songs[currentSongIndex];
    if (currentSectionIndex < 0 ||
        currentSectionIndex >= currentSong.sections.length) {
      print('safty not insurred on sections');
      return sectionTiles;
    }

    // Determine the position of current section in the visible window
    int positionOfCurrent = 0; // Default: current section at top

    int totalSections = sectionCountInSongs();
    int totalSectionsBefore = sectionCountTillCurrent();
    int totalSectionsAfter =
        sectionCountAfterCurrent(totalSections, totalSectionsBefore);

    // managing the positioning of the current section
    if (totalSectionsBefore < maxSections - 1) {
      // Near the beginning
      positionOfCurrent = totalSectionsBefore;
    } else if (totalSectionsAfter < maxSections - 1) {
      // Near the end - position current section to show all remaining
      positionOfCurrent = maxSections - totalSectionsAfter - 1;
    } else {
      // Middle region - ensure we can always see the current section
      positionOfCurrent = min(1, maxSections - 1);
    }

    // Start from the current section
    int songIdx = currentSongIndex;
    int sectionIdx = currentSectionIndex;

    // Navigate backward to find start position
    // But make sure we don't go past the beginning
    int stepsBack = min(positionOfCurrent, totalSectionsBefore);
    for (int i = 0; i < stepsBack; i++) {
      sectionIdx--;
      if (sectionIdx < 0) {
        songIdx--;
        sectionIdx = songs[songIdx].sections.length - 1;
        // Skip empty songs, importat becasue sonst error
        while (songIdx >= 0 && songs[songIdx].sections.isEmpty) {
          songIdx--;
          if (songIdx < 0) break;
        }
        if (songIdx >= 0) {
          sectionIdx = songs[songIdx].sections.length - 1;
        }
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
        count--;
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

  // Util funcs
  int sectionCountInSongs() {
    // Calculate total sections count in all songs
    int totalSections = 0;
    for (int s = 0; s < songs.length; s++) {
      totalSections += songs[s].sections.length;
    }
    return totalSections;
  }

  int sectionCountTillCurrent() {
    // length of all Sections till the current
    int totalSectionsBefore = 0;
    for (int s = 0; s < currentSongIndex; s++) {
      totalSectionsBefore += songs[s].sections.length;
    }
    totalSectionsBefore += currentSectionIndex;
    return totalSectionsBefore;
  }

  int sectionCountAfterCurrent(totalSections, totalSectionsBefore) {
    return totalSections - totalSectionsBefore - 1;
  }
}
