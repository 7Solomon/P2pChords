import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class QuickSelectOverlay extends StatefulWidget {
  final List<Song> songs;
  final String currentsong;
  final Function(String) onItemSelected;
  final Widget child;

  const QuickSelectOverlay({
    super.key,
    required this.songs,
    required this.currentsong,
    required this.onItemSelected,
    required this.child,
  });

  @override
  State<QuickSelectOverlay> createState() => QuickSelectOverlayState();
}

class QuickSelectOverlayState extends State<QuickSelectOverlay>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  double _startY = 0;
  double _currentY = 0;

  late int _selectedIndex;
  final double _itemHeight = 56.0;
  ScrollController? _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Quick jump alphabet
  final List<String> _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _selectedIndex =
        widget.songs.indexWhere((song) => song.hash == widget.currentsong);
    if (_selectedIndex < 0) _selectedIndex = 0;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(QuickSelectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update selected index when songs or current song changes
    _selectedIndex =
        widget.songs.indexWhere((song) => song.hash == widget.currentsong);
    if (_selectedIndex < 0) _selectedIndex = 0;

    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry!.markNeedsBuild();
        _scrollToSelectedIndex();
      });
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _animationController.dispose();
    _hideOverlay();
    super.dispose();
  }

  // Public method to show overlay programmatically if needed
  void showOverlay() {
    if (_overlayEntry != null) return;

    // Use the center of the screen as default position
    final size = MediaQuery.of(context).size;
    final position = Offset(size.width * 0.8, size.height / 2);
    _showOverlay(context, position);
  }

  void _showOverlay(BuildContext context, Offset position) {
    _overlayEntry?.remove();
    _startY = position.dy;
    _currentY = position.dy;

    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                // Background scrim
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _hideOverlay,
                    onPanEnd: (_) => _hideOverlay(),
                    child: Container(
                      color: Colors.black.withOpacity(0.4 * _animation.value),
                    ),
                  ),
                ),
                // Slide-in panel
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(250 * (1 - _animation.value), 0),
                    child: Stack(
                      children: [
                        // Main panel
                        Container(
                          width: 250,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).canvasColor.withOpacity(0.97),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.elliptical(120, 800),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(-5, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    const Icon(Icons.music_note, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Songs",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              Expanded(
                                child: _buildSongList(),
                              ),
                            ],
                          ),
                        ),

                        // Alphabet quick-jump
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(4),
                              ),
                            ),
                            child: _buildAlphabetSelector(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    // Initial scroll to center current item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIndex();
    });
  }

  Widget _buildSongList() {
    return ShaderMask(
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
          [0.0, 0.1, 0.9, 1.0],
        );
      },
      blendMode: BlendMode.dstIn,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            _updateSelectionFromScroll(scrollNotification.metrics.pixels);
          }
          return true;
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.songs.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedIndex;
            final song = widget.songs[index];
            final distanceFromSelected = (index - _selectedIndex).abs();

            // Calculate opacity based on distance from selected item
            final opacity = distanceFromSelected <= 2
                ? 1.0
                : distanceFromSelected <= 4
                    ? 0.5
                    : 0.3;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: opacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
                child: Container(
                  height: _itemHeight,
                  margin: EdgeInsets.symmetric(
                    horizontal: isSelected ? 8.0 : 16.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          widget.onItemSelected(song.hash);
                          _hideOverlay();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.header.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                  if (song.header.authors.isNotEmpty)
                                    Text(
                                      song.header.authors.toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlphabetSelector() {
    return ListView.builder(
      itemCount: _alphabet.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _jumpToLetter(_alphabet[index]),
          child: Container(
            height: 16,
            alignment: Alignment.center,
            child: Text(
              _alphabet[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  void _jumpToLetter(String letter) {
    // Find first song starting with this letter
    final index = widget.songs.indexWhere((song) {
      final firstLetter =
          song.header.name.isNotEmpty ? song.header.name[0].toUpperCase() : '';

      if (letter == '#') {
        // Jump to songs starting with numbers or symbols
        return !RegExp(r'[A-Za-z]').hasMatch(firstLetter);
      }

      return firstLetter == letter;
    });

    if (index != -1) {
      setState(() {
        _selectedIndex = index;
        widget.onItemSelected(widget.songs[index].hash);
        _scrollToSelectedIndex();
      });
    }
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  void _scrollToSelectedIndex() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final targetOffset = _selectedIndex * _itemHeight -
        (MediaQuery.of(context).size.height / 2) +
        (_itemHeight / 2);

    _scrollController!.animateTo(
      targetOffset.clamp(0.0, _scrollController!.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _updateSelectionFromScroll(double scrollPixels) {
    final middleOffset =
        scrollPixels + (MediaQuery.of(context).size.height / 2);
    final newIndex =
        (middleOffset / _itemHeight).round().clamp(0, widget.songs.length - 1);

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
        widget.onItemSelected(widget.songs[_selectedIndex].hash);
      });
    }
  }

  void _updateSelection(double dy) {
    if (_overlayEntry == null) return;

    _currentY = dy;
    final difference = _currentY - _startY;
    final indexOffset = (difference / _itemHeight).round();
    final newIndex =
        (_selectedIndex + indexOffset).clamp(0, widget.songs.length - 1);

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
        widget.onItemSelected(widget.songs[_selectedIndex].hash);
        _scrollToSelectedIndex();
      });

      // Reset start position to avoid jumps
      _startY = _currentY;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pass-through all touches to the child widget
        widget.child,

        // Invisible overlay that captures gestures
        Positioned.fill(
          child: GestureDetector(
            // Make detector transparent to allow interactions with widgets below
            behavior: HitTestBehavior.translucent,

            // Long press to show the overlay
            onLongPress: () => showOverlay(),

            // For vertical dragging during long press
            onLongPressMoveUpdate: (details) =>
                _updateSelection(details.globalPosition.dy),

            // When long press ends
            onLongPressEnd: (_) => _hideOverlay(),

            // No-op tap handler to ensure gesture detector doesn't interfere with regular taps
            onTap: () {},

            // Invisible container
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
