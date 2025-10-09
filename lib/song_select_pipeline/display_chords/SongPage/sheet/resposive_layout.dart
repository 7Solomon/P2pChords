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
  final Widget Function(LineData) buildLine;

  const ResponsiveLayout({
    super.key,
    required this.songs,
    required this.currentSectionIndex,
    required this.currentSongIndex,
    required this.buildLine,
  });

  @override
  Widget build(BuildContext context) {
    final uiVariables = Provider.of<SheetUiProvider>(context).uiVariables;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sectionsToDisplay = _collectSections(uiVariables);

        if (sectionsToDisplay.isEmpty) {
          return const Center(child: Text("No sections to display"));
        }

        // Switch between different layout modes
        return ValueListenableBuilder<SheetLayoutMode>(
          valueListenable: uiVariables.layoutMode,
          builder: (context, mode, _) {
            switch (mode) {
              case SheetLayoutMode.singleSection:
                return _buildSingleSectionLayout(sectionsToDisplay, uiVariables);
              case SheetLayoutMode.verticalStack:
                return _buildVerticalStackLayout(sectionsToDisplay, uiVariables);
              case SheetLayoutMode.multiColumn:
                return _buildMultiColumnLayout(sectionsToDisplay, uiVariables, uniform: false);
              case SheetLayoutMode.multiColumnUniform:
                return _buildMultiColumnLayout(sectionsToDisplay, uiVariables, uniform: true);
              default:
                return _buildVerticalStackLayout(sectionsToDisplay, uiVariables);
            }
          },
        );
      },
    );
  }

  // Vertical Stack Layout - sections flow downward with constrained width
  Widget _buildVerticalStackLayout(List<SectionTile> sections, UiVariables uiVariables) {
    // Create keys for scrolling
    final Map<int, GlobalKey> sectionKeys = {};
    for (int i = 0; i < sections.length; i++) {
      sectionKeys[i] = GlobalKey();
    }

    // Find current section index
    int currentIndex = _findCurrentSectionIndex(sections);

    // Scroll to current section after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentIndex >= 0 && 
          currentIndex < sections.length &&
          sectionKeys[currentIndex]?.currentContext != null) {
        Scrollable.ensureVisible(
          sectionKeys[currentIndex]!.currentContext!,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
          curve: Curves.easeInOut,
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: max(600.0, uiVariables.columnWidth.value * 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections.asMap().entries.map((entry) {
              return Padding(
                key: sectionKeys[entry.key],
                padding: EdgeInsets.only(bottom: uiVariables.rowSpacing.value),
                child: entry.value,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Single Section Layout - only current section visible
  Widget _buildSingleSectionLayout(List<SectionTile> sections, UiVariables uiVariables) {
    final currentSection = sections.firstWhere(
      (tile) => tile.songIndex == currentSongIndex && 
                tile.sectionIndex == currentSectionIndex,
      orElse: () => sections.first,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: max(600.0, uiVariables.columnWidth.value * 2),
          ),
          child: currentSection,
        ),
      ),
    );
  }

  // Multi Column Layout - sections in configurable columns, aligned in rows
  Widget _buildMultiColumnLayout(
    List<SectionTile> sections, 
    UiVariables uiVariables,
    {required bool uniform}
  ) {
    final columnCount = uiVariables.columnCount.value;
    
    // Create keys for scrolling
    final Map<int, GlobalKey> sectionKeys = {};
    for (int i = 0; i < sections.length; i++) {
      sectionKeys[i] = GlobalKey();
    }

    // Find current section index
    int currentIndex = _findCurrentSectionIndex(sections);

    // Scroll to current section after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentIndex >= 0 && 
          currentIndex < sections.length &&
          sectionKeys[currentIndex]?.currentContext != null) {
        Scrollable.ensureVisible(
          sectionKeys[currentIndex]!.currentContext!,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
          curve: Curves.easeInOut,
        );
      }
    });

    // Build rows
    final rows = <Widget>[];
    for (int i = 0; i < sections.length; i += columnCount) {
      final rowSections = <SectionTile>[];
      final rowKeys = <GlobalKey>[];
      
      // Collect sections for this row
      for (int j = 0; j < columnCount; j++) {
        final index = i + j;
        if (index < sections.length) {
          rowSections.add(sections[index]);
          rowKeys.add(sectionKeys[index]!);
        }
      }

      // Create row based on mode
      Widget row;
      if (uniform) {
        row = _UniformHeightRow(
          sections: rowSections,
          keys: rowKeys,
          columnCount: columnCount,
          columnSpacing: uiVariables.columnSpacing.value,
        );
      } else {
        // Non-uniform: original implementation
        final rowWidgets = <Widget>[];
        for (int j = 0; j < columnCount; j++) {
          final index = i + j;
          if (index < sections.length) {
            rowWidgets.add(
              Expanded(
                child: Padding(
                  key: sectionKeys[index],
                  padding: EdgeInsets.only(
                    right: j < columnCount - 1 ? uiVariables.columnSpacing.value : 0,
                  ),
                  child: sections[index],
                ),
              ),
            );
          } else {
            rowWidgets.add(
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: j < columnCount - 1 ? uiVariables.columnSpacing.value : 0,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            );
          }
        }
        
        row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowWidgets,
        );
      }

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: uiVariables.rowSpacing.value),
          child: row,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  // Helper to find current section in the list
  int _findCurrentSectionIndex(List<SectionTile> sections) {
    for (int i = 0; i < sections.length; i++) {
      if (sections[i].songIndex == currentSongIndex &&
          sections[i].sectionIndex == currentSectionIndex) {
        return i;
      }
    }
    return -1;
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

    // Get layout mode to adjust collection strategy
    final layoutMode = uiVariables.layoutMode.value;

    // For single section mode, only return the current section
    if (layoutMode == SheetLayoutMode.singleSection) {
      sectionTiles.add(
        SectionTile(
          song: currentSong,
          section: currentSong.sections[currentSectionIndex],
          songIndex: currentSongIndex,
          sectionIndex: currentSectionIndex,
          isFirstSectionOfSong: currentSectionIndex == 0,
          isLastSectionOfSong: currentSectionIndex == currentSong.sections.length - 1,
          isCurrentSection: true,
          isCurrentSong: true,
          buildLine: buildLine,
        ),
      );
      return sectionTiles;
    }

    // Calculate total sections
    int totalSections = sectionCountInSongs();
    int totalSectionsBefore = sectionCountTillCurrent();
    int totalSectionsAfter = sectionCountAfterCurrent(totalSections, totalSectionsBefore);

    // Determine positioning strategy based on layout mode
    int positionOfCurrent;
    
    if (layoutMode == SheetLayoutMode.verticalStack || 
        layoutMode == SheetLayoutMode.multiColumn) {
      // For vertical layouts, keep current section near top (better for reading flow)
      if (totalSectionsBefore < 1) {
        positionOfCurrent = totalSectionsBefore;
      } else if (totalSectionsAfter < maxSections - 2) {
        // Near the end
        positionOfCurrent = maxSections - totalSectionsAfter - 1;
      } else {
        // Middle region - show current at position 1 (one section above visible)
        positionOfCurrent = 1;
      }
    } else {
      // For horizontal grid, use original logic (current more centered)
      if (totalSectionsBefore < maxSections - 1) {
        positionOfCurrent = totalSectionsBefore;
      } else if (totalSectionsAfter < maxSections - 1) {
        positionOfCurrent = maxSections - totalSectionsAfter - 1;
      } else {
        positionOfCurrent = min(1, maxSections - 1);
      }
    }

    // Start from the current section
    int songIdx = currentSongIndex;
    int sectionIdx = currentSectionIndex;

    // Navigate backward to find start position
    int stepsBack = min(positionOfCurrent, totalSectionsBefore);
    for (int i = 0; i < stepsBack; i++) {
      sectionIdx--;
      if (sectionIdx < 0) {
        songIdx--;
        // Skip empty songs
        while (songIdx >= 0 && songs[songIdx].sections.isEmpty) {
          songIdx--;
          if (songIdx < 0) break;
        }
        if (songIdx >= 0) {
          sectionIdx = songs[songIdx].sections.length - 1;
        }
      }
    }

    // Collect sections
    for (int count = 0; count < maxSections; count++) {
      if (songIdx < 0 || songIdx >= songs.length) break;

      // Handle edge case of empty sections
      if (songs[songIdx].sections.isEmpty) {
        songIdx++;
        count--;
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
        continue;
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
    int totalSections = 0;
    for (int s = 0; s < songs.length; s++) {
      totalSections += songs[s].sections.length;
    }
    return totalSections;
  }

  int sectionCountTillCurrent() {
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

/// Custom widget that measures children and applies uniform height
class _UniformHeightRow extends StatefulWidget {
  final List<SectionTile> sections;
  final List<GlobalKey> keys;
  final int columnCount;
  final double columnSpacing;

  const _UniformHeightRow({
    required this.sections,
    required this.keys,
    required this.columnCount,
    required this.columnSpacing,
  });

  @override
  State<_UniformHeightRow> createState() => _UniformHeightRowState();
}

class _UniformHeightRowState extends State<_UniformHeightRow> {
  final List<GlobalKey> _childKeys = [];
  double? _uniformHeight;

  @override
  void initState() {
    super.initState();
    _childKeys.addAll(List.generate(widget.sections.length, (_) => GlobalKey()));
    
    // Measure after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChildren());
  }

  void _measureChildren() {
    double maxHeight = 0;
    
    for (final key in _childKeys) {
      final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        maxHeight = max(maxHeight, renderBox.size.height);
      }
    }
    
    if (maxHeight > 0 && _uniformHeight != maxHeight) {
      setState(() {
        _uniformHeight = maxHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowWidgets = <Widget>[];
    
    for (int j = 0; j < widget.columnCount; j++) {
      if (j < widget.sections.length) {
        rowWidgets.add(
          Expanded(
            child: Container(
              key: widget.keys[j],
              height: _uniformHeight,
              padding: EdgeInsets.only(
                right: j < widget.columnCount - 1 ? widget.columnSpacing : 0,
              ),
              child: Container(
                key: _childKeys[j],
                child: widget.sections[j],
              ),
            ),
          ),
        );
      } else {
        // Empty spacer
        rowWidgets.add(
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: j < widget.columnCount - 1 ? widget.columnSpacing : 0,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        );
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowWidgets,
    );
  }
}
