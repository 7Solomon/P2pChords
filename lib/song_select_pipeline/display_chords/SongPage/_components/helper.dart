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
    required List<List<SongSection>> sections,
    required UiVariables uiVariables,
    required Widget Function(LyricLine) buildLine,
  }) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many columns we can fit based on available width
        final availableWidth = constraints.maxWidth - 32; // Account for padding
        final columnWidth = uiVariables.columnWidth.value;
        final columnSpacing = uiVariables.columnSpacing.value;

        // Calculate max number of columns that fit in the available width
        final maxColumns = max(
            1,
            ((availableWidth + columnSpacing) / (columnWidth + columnSpacing))
                .floor());

        // Flatten sections and apply section count limit
        final List<Widget> sectionWidgets = [];
        int sectionCount = 0;
        final maxSections = uiVariables.sectionCount.value;

        // Process each song group and count sections
        for (var songGroup in sections) {
          // Start a new column for each song group
          if (sectionWidgets.isNotEmpty && sectionCount % maxColumns == 0) {
            // Need to start a new row
          }

          // Add each section from this song group
          for (var section in songGroup) {
            if (sectionCount >= maxSections) break; // Respect section limit

            sectionWidgets.add(SizedBox(
              width: columnWidth,
              child: Padding(
                padding: EdgeInsets.only(
                  right: (sectionCount % maxColumns) < maxColumns - 1
                      ? columnSpacing
                      : 0,
                  bottom: uiVariables.rowSpacing.value,
                ),
                child: buildSection(
                    section, uiVariables.fontSize.value, buildLine),
              ),
            ));
            sectionCount++;
          }
        }

        // Organize sections into a grid layout
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 0, // We handle spacing in the individual widgets
            runSpacing: 0, // We handle row spacing in the individual widgets
            children: sectionWidgets,
          ),
        );
      },
    );
  }
}

/// Animated view for sections with transitions
class SectionView extends StatelessWidget {
  final List<List<SongSection>> sections;
  final int currentIndex;
  final UiVariables uiVariables;
  final Widget Function(LyricLine) buildLineFunction;
  final bool animate;
  final int? previousIndex;

  const SectionView({
    super.key,
    required this.sections,
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
      sections: sections,
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
