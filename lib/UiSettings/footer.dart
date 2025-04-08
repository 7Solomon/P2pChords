import 'package:flutter/material.dart';
import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/UiSettings/ui_styles.dart';

class SongControlsFooter extends StatefulWidget {
  final ValueNotifier<bool> showControlsNotifier;
  final UiVariables uiVariables;
  final Function(UiVariables) onUiVariablesChanged;
  final VoidCallback onCloseTap;

  const SongControlsFooter({
    Key? key,
    required this.showControlsNotifier,
    required this.uiVariables,
    required this.onUiVariablesChanged,
    required this.onCloseTap,
  }) : super(key: key);

  @override
  State<SongControlsFooter> createState() => _SongControlsFooterState();
}

class _SongControlsFooterState extends State<SongControlsFooter> {
  // State persists between rebuilds
  final ValueNotifier<Offset> panelPosition = ValueNotifier(const Offset(0, 0));
  final ValueNotifier<bool> animationCompleted = ValueNotifier(false);
  bool isDragging = false;

  @override
  void dispose() {
    panelPosition.dispose();
    animationCompleted.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: panelPosition,
      builder: (context, position, _) {
        return Positioned(
          right: position.dx == 0 ? 16.0 : null,
          bottom: position.dy == 0 ? 16.0 : null,
          left: position.dx != 0 ? position.dx : null,
          top: position.dy != 0 ? position.dy : null,
          child: ValueListenableBuilder(
            valueListenable: widget.showControlsNotifier,
            builder: (context, showControls, _) {
              // Reset animation completion status when visibility changes
              if (!showControls) {
                Future.microtask(() => animationCompleted.value = false);
              }

              return Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Main controls panel
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: showControls ? 320 : 0,
                    height: showControls ? 400 : 0,
                    decoration: UiStyles.floatingPanelDecoration,
                    padding:
                        showControls ? UiStyles.smallPadding : EdgeInsets.zero,
                    onEnd: () {
                      // Mark animation as completed
                      if (showControls) {
                        animationCompleted.value = true;
                      }
                    },
                    child: showControls
                        ? ValueListenableBuilder(
                            valueListenable: animationCompleted,
                            builder: (context, isComplete, _) {
                              return AnimatedOpacity(
                                opacity: isComplete ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 150),
                                child: isComplete
                                    ? _buildTabContent()
                                    : const SizedBox.shrink(),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Quick access button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      mini: !showControls,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        // Reset position when toggling with FAB
                        if (showControls) {
                          panelPosition.value = const Offset(0, 0);
                        }
                        widget.showControlsNotifier.value = !showControls;
                      },
                      child: Icon(
                        showControls ? Icons.close : Icons.settings,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Draggable header
          GestureDetector(
            onPanStart: (_) => setState(() => isDragging = true),
            onPanEnd: (_) => setState(() => isDragging = false),
            onPanUpdate: (details) {
              panelPosition.value = Offset(
                panelPosition.value.dx + details.delta.dx,
                panelPosition.value.dy + details.delta.dy,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDragging
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.drag_indicator, size: 16),
                  const SizedBox(width: 8),
                  const Text('Settings', style: UiStyles.headingStyle),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      panelPosition.value = const Offset(0, 0);
                      widget.onCloseTap();
                    },
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.text_fields),
                text: 'Text',
              ),
              Tab(
                icon: Icon(Icons.space_bar),
                text: 'Spacing',
              ),
              Tab(
                icon: Icon(Icons.view_column),
                text: 'Layout',
              ),
            ],
            labelColor: UiStyles.primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                // Text Tab
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ControlsRow(
                      label: 'Schriftgröße',
                      value:
                          widget.uiVariables.fontSize.value.toStringAsFixed(1),
                      minValue:
                          widget.uiVariables.fontSize.min.toStringAsFixed(1),
                      maxValue:
                          widget.uiVariables.fontSize.max.toStringAsFixed(1),
                      onDecrease: () {
                        widget.uiVariables.fontSize.value -= 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                      onIncrease: () {
                        widget.uiVariables.fontSize.value += 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                    ),
                  ],
                ),
                // Spacing Tab
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ControlsRow(
                      label: 'Linien Abstand',
                      value: widget.uiVariables.lineSpacing.value
                          .toStringAsFixed(1),
                      minValue:
                          widget.uiVariables.lineSpacing.min.toStringAsFixed(1),
                      maxValue:
                          widget.uiVariables.lineSpacing.max.toStringAsFixed(1),
                      onDecrease: () {
                        widget.uiVariables.lineSpacing.value -= 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                        ;
                      },
                      onIncrease: () {
                        widget.uiVariables.lineSpacing.value += 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                    ),
                    ControlsRow(
                      label: 'Abstand zwischen Zeilen',
                      value: widget.uiVariables.rowSpacing.value
                          .toStringAsFixed(1),
                      minValue:
                          widget.uiVariables.rowSpacing.min.toStringAsFixed(1),
                      maxValue:
                          widget.uiVariables.rowSpacing.max.toStringAsFixed(1),
                      onDecrease: () {
                        widget.uiVariables.rowSpacing.value -= 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                      onIncrease: () {
                        widget.uiVariables.rowSpacing.value += 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                    ),
                    ControlsRow(
                      label: 'Abstand zwischen Spalten',
                      value: widget.uiVariables.columnSpacing.value
                          .toStringAsFixed(1),
                      minValue: widget.uiVariables.columnSpacing.min
                          .toStringAsFixed(1),
                      maxValue: widget.uiVariables.columnSpacing.max
                          .toStringAsFixed(1),
                      onDecrease: () {
                        widget.uiVariables.columnSpacing.value -= 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                      onIncrease: () {
                        widget.uiVariables.columnSpacing.value += 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                    ),
                  ],
                ),
                // Layout Tab
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ControlsRow(
                      label: 'Anzahl Sections',
                      value: widget.uiVariables.sectionCount.value.toString(),
                      minValue: widget.uiVariables.sectionCount.min.toString(),
                      maxValue: widget.uiVariables.sectionCount.max.toString(),
                      onDecrease: () {
                        widget.uiVariables.sectionCount.value -= 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                      onIncrease: () {
                        widget.uiVariables.sectionCount.value += 1;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                    ),
                    ControlsRow(
                      label: 'Breite der Spalten',
                      value: widget.uiVariables.columnWidth.value
                          .toStringAsFixed(0),
                      minValue:
                          widget.uiVariables.columnWidth.min.toStringAsFixed(0),
                      maxValue:
                          widget.uiVariables.columnWidth.max.toStringAsFixed(0),
                      onDecrease: () {
                        widget.uiVariables.columnWidth.value -= 10;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                      onIncrease: () {
                        widget.uiVariables.columnWidth.value += 10;
                        widget.onUiVariablesChanged(widget.uiVariables);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
