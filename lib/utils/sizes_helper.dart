import 'package:flutter/material.dart';

Size displaySize(BuildContext context) {
  return MediaQuery.of(context).size;
}

double displayHeight(BuildContext context) {
  return displaySize(context).height;
}

double displayWidth(BuildContext context) {
  return displaySize(context).width;
}

bool isSmallScreen(BuildContext context) {
  final mediaQueryData = MediaQuery.of(context);
  final screenHeight = mediaQueryData.size.height;
  return screenHeight < 844;
}