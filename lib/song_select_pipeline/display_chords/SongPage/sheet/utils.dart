import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

class TapFriendlyScrollPhysics extends ClampingScrollPhysics {
  const TapFriendlyScrollPhysics({super.parent});

  @override
  TapFriendlyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TapFriendlyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold =>
      100.0; // Higher threshold for drag vs. tap
}
