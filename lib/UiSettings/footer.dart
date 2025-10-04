import 'package:flutter/material.dart';
import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/UiSettings/ui_styles.dart';

class SongControlsFooter extends StatefulWidget {
  final ValueNotifier<bool> showControlsNotifier;
  final UiVariables uiVariables;
  final Function(UiVariables) onUiVariablesChanged;
  final VoidCallback onCloseTap;

  const SongControlsFooter({
    super.key,
    required this.showControlsNotifier,
    required this.uiVariables,
    required this.onUiVariablesChanged,
    required this.onCloseTap,
  });

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
                    height: showControls ? 450 : 0, // Increased height for 4 tabs
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
    // Define control configurations
    final controlConfigs = [
      // Text Tab Controls
      {
        'tab': 0,
        'label': 'Schriftgröße',
        'property': 'fontSize',
        'step': 1.0,
        'type': 'double',
      },

      // Spacing Tab Controls
      {
        'tab': 1,
        'label': 'Linien Abstand',
        'property': 'lineSpacing',
        'step': 1.0,
        'type': 'double',
      },
      {
        'tab': 1,
        'label': 'Abstand zwischen Zeilen',
        'property': 'rowSpacing',
        'step': 1.0,
        'type': 'double',
      },
      {
        'tab': 1,
        'label': 'Abstand zwischen Spalten',
        'property': 'columnSpacing',
        'step': 1.0,
        'type': 'double',
      },

      // Layout Tab Controls
      {
        'tab': 2,
        'label': 'Anzahl Sections',
        'property': 'sectionCount',
        'step': 1.0,
        'formatDecimals': 0,
        'type': 'int',
      },
      {
        'tab': 2,
        'label': 'Breite der Spalten',
        'property': 'columnWidth',
        'step': 10.0,
        'formatDecimals': 0,
        'type': 'double',
      },
      {
        'tab': 2,
        'label': 'Anzahl Spalten',
        'property': 'columnCount',
        'step': 1.0,
        'formatDecimals': 0,
        'type': 'int',
      },
    ];

    // Create tab contents based on configurations
    List<Widget> buildTabContent(int tabIndex) {
      return controlConfigs
          .where((config) => config['tab'] == tabIndex)
          .map((config) {
        final property = config['property'] as String;
        final step = config['step'] as double;
        final decimals = config['formatDecimals'] as int? ?? 1;
        final type = config['type'] as String;

        // Get the corresponding variable from uiVariables
        final variable = widget.uiVariables.getProperty(property);

        return ControlsRow(
          label: config['label'] as String,
          value: variable.value.toStringAsFixed(decimals),
          minValue: variable.min.toStringAsFixed(decimals),
          maxValue: variable.max.toStringAsFixed(decimals),
          onDecrease: () {
            if (type == 'int') {
              variable.value = (variable.value - step).toInt();
            } else {
              variable.value -= step;
            }
            widget.onUiVariablesChanged(widget.uiVariables);
          },
          onIncrease: () {
            if (type == 'int') {
              variable.value = (variable.value + step).toInt();
            } else {
              variable.value += step;
            }
            widget.onUiVariablesChanged(widget.uiVariables);
          },
        );
      }).toList();
    }

    return DefaultTabController(
      length: 4, 
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
              Tab(icon: Icon(Icons.text_fields), text: 'Text'),
              Tab(icon: Icon(Icons.space_bar), text: 'Spacing'),
              Tab(icon: Icon(Icons.view_column), text: 'Layout'),
              Tab(icon: Icon(Icons.view_agenda), text: 'Mode'), // New tab
            ],
            labelColor: UiStyles.primaryColor,
            unselectedLabelColor: Colors.grey,
            isScrollable: true, // Make tabs scrollable if needed
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                // Text Tab
                ListView(
                  padding: EdgeInsets.zero,
                  children: buildTabContent(0),
                ),
                // Spacing Tab
                ListView(
                  padding: EdgeInsets.zero,
                  children: buildTabContent(1),
                ),
                // Layout Tab
                ListView(
                  padding: EdgeInsets.zero,
                  children: buildTabContent(2),
                ),
                // Mode Tab - New!
                _buildModeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New widget for layout mode selection
  Widget _buildModeTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Text(
            'Layout Modus',
            style: UiStyles.labelStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ValueListenableBuilder<SheetLayoutMode>(
          valueListenable: widget.uiVariables.layoutMode,
          builder: (context, currentMode, _) {
            return Column(
              children: [
                _buildModeOption(
                  mode: SheetLayoutMode.verticalStack,
                  currentMode: currentMode,
                  icon: Icons.view_agenda,
                  title: 'Vertikal Stapeln',
                  description: 'Sections fließen nach unten (empfohlen)',
                ),
                _buildModeOption(
                  mode: SheetLayoutMode.singleSection,
                  currentMode: currentMode,
                  icon: Icons.fullscreen,
                  title: 'Einzelne Section',
                  description: 'Nur aktuelle Section anzeigen',
                ),
                _buildModeOption(
                  mode: SheetLayoutMode.multiColumn,
                  currentMode: currentMode,
                  icon: Icons.view_week,
                  title: 'Mehrere Spalten',
                  description: 'Sections in Raster (siehe Layout-Tab)',
                ),
                _buildModeOption(
                  mode: SheetLayoutMode.horizontalGrid,
                  currentMode: currentMode,
                  icon: Icons.grid_view,
                  title: 'Horizontal Grid',
                  description: 'Sections fließen horizontal',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required SheetLayoutMode mode,
    required SheetLayoutMode currentMode,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = mode == currentMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          widget.uiVariables.layoutMode.value = mode;
          widget.onUiVariablesChanged(widget.uiVariables);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isSelected
                ? UiStyles.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? UiStyles.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? UiStyles.primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? UiStyles.primaryColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: UiStyles.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
