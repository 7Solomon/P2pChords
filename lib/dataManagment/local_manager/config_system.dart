import 'package:flutter/material.dart';

class PrivateFeatures {
  static final PrivateFeatures _instance = PrivateFeatures._internal();
  factory PrivateFeatures() => _instance;
  PrivateFeatures._internal();

  final bool hasHalfLegalStuff = false;

  Widget buildHalfLegalWidget(BuildContext context) {
    return const SizedBox.shrink();
  }
}
