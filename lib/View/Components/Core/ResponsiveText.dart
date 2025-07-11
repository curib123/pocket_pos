import 'package:flutter/material.dart';

double getResponsiveText(BuildContext context, double baseSize) {
  double screenWidth = MediaQuery.of(context).size.width;

  if (screenWidth >= 1200) {
    return baseSize * 2.2;
  } else if (screenWidth >= 900) {
    return baseSize * 1.8;
  } else if (screenWidth >= 600) {
    return baseSize * 1.4;
  } else {
    return baseSize;
  }
}

// Optional Extension for cleaner usage: context.rf(14)
extension ResponsiveTextExtension on BuildContext {
  double rf(double baseSize) => getResponsiveText(this, baseSize);
}
