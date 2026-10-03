import 'package:flutter/material.dart';
import 'package:nextpos/core/brand/app_brand.dart';

class BantayStockMark extends StatelessWidget {
  final double size;
  final bool filled;

  const BantayStockMark({
    super.key,
    this.size = 40,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final markColor = filled ? Colors.white : AppBrand.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? AppBrand.primary : AppBrand.primarySoftOf(context),
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Stack(
        children: [
          Positioned(
            left: size * .27,
            top: size * .20,
            width: size * .12,
            height: size * .60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: markColor,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          for (final top in [.20, .44, .68])
            Positioned(
              left: size * .27,
              top: size * top,
              width: size * .46,
              height: size * .12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: markColor,
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BantayStockBrand extends StatelessWidget {
  final bool showTagline;
  final double markSize;

  const BantayStockBrand({
    super.key,
    this.showTagline = false,
    this.markSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BantayStockMark(size: markSize),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppBrand.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (showTagline)
                Text(
                  AppBrand.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppBrand.mutedOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
