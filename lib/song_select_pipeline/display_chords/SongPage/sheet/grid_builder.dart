import 'dart:math';

import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/line_builds.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/section_tile.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class CGridViewBuild extends StatelessWidget {
  final List<SectionTile> sectionsToDisplay;

  final int currentSectionIndex;
  final int currentSongIndex;

  final Widget Function(LineData) buildLine;

  const CGridViewBuild({
    super.key,
    required this.currentSectionIndex,
    required this.currentSongIndex,
    required this.sectionsToDisplay,
    required this.buildLine,
  });

  @override
  Widget build(BuildContext context) {
    final uiVariables = Provider.of<SheetUiProvider>(context).uiVariables;

    // Calculate optimal layout values
    final double columnWidth = max(250.0, uiVariables.columnWidth.value);
    final double columnSpacing = uiVariables.columnSpacing.value;

    // Create a key for the current section for scrolling
    final Map<int, GlobalKey> sectionKeys = {};
    for (int i = 0; i < sectionsToDisplay.length; i++) {
      sectionKeys[i] = GlobalKey();
    }

    // Scroll to current section after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentSectionIndex >= 0 &&
          currentSectionIndex < sectionsToDisplay.length &&
          sectionKeys[currentSectionIndex]?.currentContext != null) {
        Scrollable.ensureVisible(
          sectionKeys[currentSectionIndex]!.currentContext!,
          duration: const Duration(milliseconds: 300),
          alignment: 0.0,
        );
      }
    });

    return AlignedGridView.count(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling in this view, because is handled by the parent widget du kek
      crossAxisCount: (MediaQuery.of(context).size.width / columnWidth).floor(),
      mainAxisSpacing: uiVariables.rowSpacing.value,
      crossAxisSpacing: columnSpacing,
      itemCount: sectionsToDisplay.length,
      itemBuilder: (context, index) {
        final SectionTile sectionTile = sectionsToDisplay[index];

        return Container(
          key: sectionKeys[index],
          child: sectionTile,
        );
      },
    );
  }
}
