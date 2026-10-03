import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextpos/View/Components/Brand/BantayStockBrand.dart';
import 'package:nextpos/core/brand/app_brand.dart';

void main() {
  testWidgets('BantayStock brand lockup is readable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BantayStockBrand(showTagline: true),
          ),
        ),
      ),
    );

    expect(find.text(AppBrand.name), findsOneWidget);
    expect(find.text(AppBrand.tagline), findsOneWidget);
    expect(find.byType(BantayStockMark), findsOneWidget);
  });
}
