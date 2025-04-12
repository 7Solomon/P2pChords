import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required this.child,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    return _MeasureSizeRenderObject(
      onChange: widget.onChange,
      child: widget.child,
    );
  }
}

class _MeasureSizeRenderObject extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  const _MeasureSizeRenderObject({
    required this.onChange,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderBox(onChange);
  }
}

class _MeasureSizeRenderBox extends RenderProxyBox {
  final OnWidgetSizeChange onChange;
  Size? _prevSize;

  _MeasureSizeRenderBox(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = size;
    if (_prevSize == null || _prevSize != newSize) {
      _prevSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}
