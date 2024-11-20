import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class QuickSelectOverlay extends StatefulWidget {
  final Map items; // Changed to Map
  final String currentsong; // Current selected key
  final Function(String) onItemSelected; // Now passes the key instead of value
  final Widget child;

  const QuickSelectOverlay({
    Key? key,
    required this.items,
    required this.currentsong,
    required this.onItemSelected,
    required this.child,
  }) : super(key: key);

  @override
  State<QuickSelectOverlay> createState() => _QuickSelectOverlayState();
}

class _QuickSelectOverlayState extends State<QuickSelectOverlay> {
  OverlayEntry? _overlayEntry;
  double _startY = 0;
  double _currentY = 0;
  late List<String> _orderedKeys; // Store keys in order
  late int _selectedIndex;
  final double _itemHeight = 56.0;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeOrderedKeys();
  }

  void _initializeOrderedKeys() {
    // Get all keys and sort them into before and after current
    List<String> beforeCurrent = [];
    List<String> afterCurrent = [];

    widget.items.keys.forEach((key) {
      if (key == widget.currentsong) return;
      if (key.compareTo(widget.currentsong) < 0) {
        beforeCurrent.add(key);
      } else {
        afterCurrent.add(key);
      }
    });

    // Sort both lists
    beforeCurrent.sort();
    afterCurrent.sort();

    // Combine lists with current key in the middle
    _orderedKeys = [...beforeCurrent, widget.currentsong, ...afterCurrent];
    _selectedIndex = beforeCurrent.length; // Index of current key
  }

  @override
  void didUpdateWidget(QuickSelectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentsong != widget.currentsong ||
        oldWidget.items != widget.items) {
      _initializeOrderedKeys();

      if (_overlayEntry != null) {
        // Delay the rebuild until after the current build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _overlayEntry!.markNeedsBuild();
          _scrollToSelectedIndex();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  bool _isInRightQuarter(Offset position, Size size) {
    final rightQuarterStart = size.width * 0.75;
    return position.dx >= rightQuarterStart;
  }

  void _showOverlay(BuildContext context, Offset position) {
    if (!_isInRightQuarter(
        position,
        Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height,
        ))) return;

    _overlayEntry?.remove();
    _startY = position.dy;
    _currentY = position.dy;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanEnd: (_) => _hideOverlay(),
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              children: [
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.elliptical(125, 800),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(-5, 0),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Material(
                    color: Colors.transparent,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return ui.Gradient.linear(
                          Offset(0, bounds.top),
                          Offset(0, bounds.bottom),
                          [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          [0.0, 0.2, 0.8, 1.0],
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollUpdateNotification) {
                            _updateSelectionFromScroll(
                                scrollNotification.metrics.pixels);
                          }
                          return true;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _orderedKeys.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedIndex;
                            final distanceFromSelected =
                                (index - _selectedIndex).abs();
                            final opacity = distanceFromSelected <= 2
                                ? 1.0
                                : distanceFromSelected <= 3
                                    ? 0.3
                                    : 0.1;

                            final key = _orderedKeys[index];
                            final value = widget.items[key]!;

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: opacity,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.05 : 1.0),
                                child: Container(
                                  height: _itemHeight,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.15)
                                        : null,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      value['header']['name'] ??
                                          'no Name Found', // Display the value from the map
                                      style: TextStyle(
                                        fontSize: isSelected ? 16 : 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Initial scroll to center current item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIndex();
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
  }

  void _scrollToSelectedIndex() {
    if (_scrollController == null) return;

    final targetOffset = _selectedIndex * _itemHeight -
        (MediaQuery.of(context).size.height / 2) +
        (_itemHeight / 2);

    _scrollController!.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _updateSelectionFromScroll(double scrollPixels) {
    final middleOffset =
        scrollPixels + (MediaQuery.of(context).size.height / 2);
    final newIndex =
        (middleOffset / _itemHeight).round().clamp(0, _orderedKeys.length - 1);

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
        widget.onItemSelected(_orderedKeys[_selectedIndex]); // Pass the key
      });
    }
  }

  void _updateSelection(double dy) {
    if (_overlayEntry == null) return;

    _currentY = dy;
    final difference = _currentY - _startY;
    final newIndex =
        (difference / _itemHeight).round().clamp(0, _orderedKeys.length - 1);

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
        widget.onItemSelected(_orderedKeys[_selectedIndex]); // Pass the key
        _scrollToSelectedIndex();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onLongPressStart: (details) =>
              _showOverlay(context, details.globalPosition),
          onLongPressMoveUpdate: (details) =>
              _updateSelection(details.globalPosition.dy),
          onLongPressEnd: (_) => _hideOverlay(),
          child: widget.child,
        );
      },
    );
  }
}
