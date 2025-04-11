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
  }) : super(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
        );
}
