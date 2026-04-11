import 'package:flutter/material.dart';

class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve exit = Curves.easeInCubic;
}
