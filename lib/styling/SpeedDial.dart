import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CSpeedDial extends SpeedDial {
  CSpeedDial({
    super.key,
    required ThemeData theme,
    required super.children,
    AnimatedIconData super.animatedIcon = AnimatedIcons.menu_close,
    Color? backgroundColor,
    Color? foregroundColor,
    super.elevation = 8.0,
    double super.spacing = 8,
    double super.spaceBetweenChildren = 8,
    super.buttonSize = const Size(65, 65),
    super.childrenButtonSize = const Size(65, 65),
  }) : super(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
        );
}

class SpeedDialCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<SpeedDialChild> children;

  SpeedDialCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });
}

class HierarchicalSpeedDial extends StatefulWidget {
  final List<SpeedDialCategory> categories;
  final ThemeData theme;
  final AnimatedIconData animatedIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double buttonSize;

  const HierarchicalSpeedDial({
    Key? key,
    required this.categories,
    required this.theme,
    this.animatedIcon = AnimatedIcons.menu_close,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 8.0,
    this.buttonSize = 65.0,
  }) : super(key: key);

  @override
  State<HierarchicalSpeedDial> createState() => _HierarchicalSpeedDialState();
}

class _HierarchicalSpeedDialState extends State<HierarchicalSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  SpeedDialCategory? _activeCategory;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // Background overlay to close dial when tapping outside
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _isOpen = false;
                    _activeCategory = null;
                    _animationController.reverse();
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          // Category Buttons
          if (_isOpen && _activeCategory == null)
            for (int i = 0; i < widget.categories.length; i++)
              _buildCategoryButton(widget.categories[i], i),

          // Child Buttons for Active Category
          if (_isOpen && _activeCategory != null) ...[
            _buildBackButton(),
            for (int i = 0; i < (_activeCategory?.children.length ?? 0); i++)
              _buildChildButton(_activeCategory!.children[i], i),
          ],

          // Main Dial Button
          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              backgroundColor:
                  widget.backgroundColor ?? widget.theme.primaryColor,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              elevation: widget.elevation,
              enableFeedback: true,
              onPressed: _toggleMainDial,
              child: AnimatedIcon(
                icon: widget.animatedIcon,
                progress: _animation,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMainDial() {
    //print("Toggling dial: current state=$_isOpen");
    setState(() {
      _isOpen = !_isOpen;
      _activeCategory = null;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    //print("After toggle: new state=$_isOpen");
  }

  void _openCategory(SpeedDialCategory category) {
    setState(() {
      _activeCategory = category;
    });
  }

  void _closeCategory() {
    setState(() {
      _activeCategory = null;
    });
  }

  // Helper methods to build individual buttons
  Widget _buildCategoryButton(SpeedDialCategory category, int index) {
    final position = (index + 1) * 65.0;

    return Positioned(
      right: 0,
      bottom: position,
      child: Row(
        children: [
          // Label
          Material(
            elevation: 2,
            color: category.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                category.title,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Button
          FloatingActionButton.small(
            heroTag: 'category_${category.title}',
            backgroundColor: category.color,
            foregroundColor: Colors.white,
            enableFeedback: true,
            child: Icon(category.icon),
            onPressed: () => _openCategory(category),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      right: 0,
      bottom: 65.0,
      child: Row(
        children: [
          // Label
          Material(
            elevation: 2,
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Zurück',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Button
          FloatingActionButton.small(
            heroTag: 'back_button',
            backgroundColor: Colors.grey.shade700,
            enableFeedback: true,
            onPressed: _closeCategory,
            child: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }

  Widget _buildChildButton(SpeedDialChild child, int index) {
    final position = (index + 2) * 65.0; // +2 to account for back button

    return Positioned(
      right: 0,
      bottom: position,
      child: Row(
        children: [
          if (child.label != null)
            Material(
              elevation: 2,
              color: (child.backgroundColor ?? _activeCategory!.color)
                  .withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  child.label!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(width: 10),
          FloatingActionButton.small(
            heroTag: 'child_${_activeCategory!.title}_$index',
            backgroundColor: child.backgroundColor ?? _activeCategory!.color,
            foregroundColor: child.foregroundColor ?? Colors.white,
            enableFeedback: true,
            child: child.child,
            onPressed: () {
              // Close the dial first
              setState(() {
                _isOpen = false;
                _activeCategory = null;
                _animationController.reverse();
              });
              // Then execute the child's onTap function
              child.onTap?.call();
            },
          ),
        ],
      ),
    );
  }
}
