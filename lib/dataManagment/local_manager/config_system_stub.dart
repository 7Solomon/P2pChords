// This will be checked into git
import 'package:flutter/material.dart';

class PrivateFeatures {
  static final PrivateFeatures _instance = PrivateFeatures._internal();
  factory PrivateFeatures() => _instance;
  PrivateFeatures._internal();

  // Define which private features are available
  final bool hasHalfLegalStuff = false;

  // Define empty stub widgets
  Widget buildHalfLegalWidget(BuildContext context) {
    return const SizedBox.shrink();
  }
}
