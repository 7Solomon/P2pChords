import 'dart:math';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/UiSettings/data_class.dart';

/// Helper class to build section widgets consistently across the app
class SectionBuilder {
  /// Builds a widget for a single section
  static Widget buildSection(SongSection section, double fontSize,
      Widget Function(LyricLine) buildLine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...section.lines.map((line) => buildLine(line)),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Build sections with automatic song detection and section limits
  static Widget buildSongSectionLayout({
    required List<Song> songs,
    required UiVariables uiVariables,
    required Widget Function(LyricLine) buildLine,
    Function(bool didOverflow)? onOverflow,
  }) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many columns we can fit based on available width
        final availableWidth = constraints.maxWidth - 32; // Account for padding
        final availableHeight = constraints.maxHeight - 32;
        final columnWidth = uiVariables.columnWidth.value;
        final columnSpacing = uiVariables.columnSpacing.value;

        // Calculate max number of columns that fit in the available width
        final maxColumns = max(
            1,
            ((availableWidth + columnSpacing) / (columnWidth + columnSpacing))
                .floor());

        // Adjust actual column width to use available space efficiently
        final actualColumnWidth =
            (availableWidth - (columnSpacing * (maxColumns - 1))) / maxColumns;

        final List<Widget> songWidgets = [];
        int totalSectionCount = 0;
        final maxSections = uiVariables.sectionCount.value;

        // Track height to detect overflow
        double estimatedHeight = 0;
        bool hasOverflowed = false;

        // Standard heights for different widget types
        final titleHeight =
            uiVariables.fontSize.value + 4 + 24.0; // Font size + padding
        final sectionTitleHeight =
            uiVariables.fontSize.value + 2 + 16.0; // Title + spacing
        final lineHeight =
            uiVariables.fontSize.value + uiVariables.lineSpacing.value;
        final rowSpacing = uiVariables.rowSpacing.value;
        final songSpacing = uiVariables.rowSpacing.value * 2;

        // Process each song separately
        for (var songIndex = 0; songIndex < songs.length; songIndex++) {
          var song = songs[songIndex];

          // Skip this song if we've already reached the max section count
          if (totalSectionCount >= maxSections) break;

          // Check if adding the song title would overflow
          if (estimatedHeight + titleHeight > availableHeight &&
              !hasOverflowed) {
            hasOverflowed = true;
            if (onOverflow != null) onOverflow(true);
            break;
          }

          // Add song title as a separate row that spans all columns
          songWidgets.add(
            Container(
              width: availableWidth, // Use calculated available width
              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
              child: Text(
                song.header.name,
                style: TextStyle(
                  fontSize: uiVariables.fontSize.value + 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

          estimatedHeight += titleHeight;

          // Create a row of sections for this song
          final List<Widget> sectionRow = [];
          int columnInCurrentRow = 0;
          double currentRowMaxHeight = 0;

          // Add each section from this song
          for (var sectionIndex = 0;
              sectionIndex < song.sections.length;
              sectionIndex++) {
            var section = song.sections[sectionIndex];
            if (totalSectionCount >= maxSections) break; // Global section limit

            // Estimate section height: title + lines + bottom spacing
            double sectionHeight = sectionTitleHeight;
            sectionHeight += section.lines.length * lineHeight;
            sectionHeight += 24; // Bottom spacing of section

            // If this is the first section in the row, check if a new row would overflow
            if (columnInCurrentRow == 0) {
              // If starting a new row would overflow
              if (estimatedHeight + sectionHeight > availableHeight &&
                  !hasOverflowed) {
                hasOverflowed = true;
                if (onOverflow != null) onOverflow(true);
                break;
              }
            }

            // Track the tallest section in this row
            currentRowMaxHeight = max(currentRowMaxHeight, sectionHeight);

            sectionRow.add(
              SizedBox(
                width: actualColumnWidth, // Use calculated width
                child: Padding(
                  padding: EdgeInsets.only(
                    right:
                        columnInCurrentRow < maxColumns - 1 ? columnSpacing : 0,
                    bottom: rowSpacing,
                  ),
                  child: buildSection(
                      section, uiVariables.fontSize.value, buildLine),
                ),
              ),
            );

            columnInCurrentRow++;
            totalSectionCount++;

            // Start a new row after we reach maxColumns
            if (columnInCurrentRow >= maxColumns) {
              songWidgets.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.from(sectionRow),
                ),
              );

              // Add this row's height to total estimated height
              estimatedHeight += currentRowMaxHeight + rowSpacing;

              sectionRow.clear();
              columnInCurrentRow = 0;
              currentRowMaxHeight = 0;
            }
          }

          // Add any remaining sections that didn't complete a row
          if (sectionRow.isNotEmpty) {
            songWidgets.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: sectionRow,
              ),
            );

            // Add this partial row's height
            estimatedHeight += currentRowMaxHeight + rowSpacing;
          }

          // Add spacing between songs
          if (songIndex < songs.length - 1) {
            songWidgets.add(SizedBox(height: songSpacing));
            estimatedHeight += songSpacing;
          }
        }

        // Call onOverflow with false if we didn't overflow
        if (!hasOverflowed && onOverflow != null) {
          onOverflow(false);
        }

        // Return the final layout without ScrollView to preserve tap detection
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: songWidgets,
          ),
        );
      },
    );
  }
}

/// Animated view for sections with transitions
class SectionView extends StatelessWidget {
  final List<Song> songs;
  final int currentIndex;
  final UiVariables uiVariables;
  final Widget Function(LyricLine) buildLineFunction;
  final bool animate;
  final int? previousIndex;

  const SectionView({
    super.key,
    required this.songs,
    required this.currentIndex,
    required this.uiVariables,
    required this.buildLineFunction,
    this.animate = true,
    this.previousIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Here we build the content for the sections
    Widget content = SectionBuilder.buildSongSectionLayout(
      songs: songs,
      uiVariables: uiVariables,
      buildLine: buildLineFunction,
    );

    // Apply animation if needed
    if (!animate || previousIndex == null) {
      return content;
    }

    // Animation logic
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool isForward = currentIndex > (previousIndex ?? 0);

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
        key: ValueKey<int>(currentIndex),
        child: content,
      ),
    );
  }
}
