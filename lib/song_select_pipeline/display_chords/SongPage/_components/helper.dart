import 'dart:math';

import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

/// Helper class to build section widgets consistently across the app
class SectionBuilder {
  /// Builds a section widget with title and content
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
}

Widget buildMultiSectionLayout({
  required List<SongSection> sections,
  required double fontSize,
  required double
      minColumnWidth, // Keep for compatibility, can be removed later
  required Widget Function(SongSection, double) buildSection,
}) {
  // Build complete section widgets
  final List<Widget> sectionWidgets =
      sections.map((section) => buildSection(section, fontSize)).toList();

  return LayoutBuilder(
    builder: (context, constraints) {
      // If only one section or narrow screen, use single column
      if (sectionWidgets.length <= 1 || constraints.maxWidth < 500) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sectionWidgets,
          ),
        );
      }

      // Calculate responsive section width
      // Default to 2 columns on most screens, 3+ on wider screens
      int columnCount = max(2, (constraints.maxWidth / 400).floor());
      double sectionWidth = constraints.maxWidth / columnCount - 24;

      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16.0, // horizontal gap between sections
          runSpacing: 24.0, // vertical gap between rows
          alignment: WrapAlignment.start,
          children: sectionWidgets
              .map((widget) => SizedBox(
                    width: sectionWidth,
                    child: widget,
                  ))
              .toList(),
        ),
      );
    },
  );
}

class AnimatedSectionView extends StatefulWidget {
  final List<SongSection> sections;
  final int currentIndex;
  final int sectionsPerView;
  final double fontSize;
  final double minColumnWidth;
  final Widget Function(SongSection, double) buildSection;
  final Function(int)? onSectionChanged;

  const AnimatedSectionView({
    Key? key,
    required this.sections,
    required this.currentIndex,
    required this.sectionsPerView,
    required this.fontSize,
    required this.minColumnWidth,
    required this.buildSection,
    this.onSectionChanged,
  }) : super(key: key);

  @override
  State<AnimatedSectionView> createState() => _AnimatedSectionViewState();
}

class _AnimatedSectionViewState extends State<AnimatedSectionView> {
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AnimatedSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Determine animation direction based on index change
        final bool isForward = widget.currentIndex > _previousIndex;

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
      child: _buildSectionContent(key: ValueKey<int>(widget.currentIndex)),
    );
  }

  Widget _buildSectionContent({Key? key}) {
    List<SongSection> sectionsToShow = [];
    for (int i = widget.currentIndex;
        i < widget.currentIndex + widget.sectionsPerView &&
            i < widget.sections.length;
        i++) {
      sectionsToShow.add(widget.sections[i]);
    }
    // Use the new multi-section layout function.
    return buildMultiSectionLayout(
      sections: sectionsToShow,
      fontSize: widget.fontSize,
      minColumnWidth: widget.minColumnWidth,
      buildSection: widget.buildSection,
    );
  }
}
