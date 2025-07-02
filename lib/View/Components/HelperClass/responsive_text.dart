import 'package:flutter/material.dart';

double getResponsiveFontSize(BuildContext context, double baseSize) {
  double screenWidth = MediaQuery.of(context).size.width;

  if (screenWidth >= 900) {
    // Tablet or large screen
    return baseSize * 2;
  } else if (screenWidth >= 600) {
    // Small tablets
    return baseSize * 2;
  } else {
    // Mobile
    return baseSize * 1;
  }
}
