import 'package:flutter/material.dart';
import 'package:nextpos/core/brand/app_brand.dart';

class PocketInventoryMark extends StatelessWidget {
  final double size;

  const PocketInventoryMark({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .24),
        child: Image.asset(
          'assets/icon/icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * .24),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: AppBrand.primary,
              size: size * .62,
            ),
          ),
        ),
      ),
    );
  }
}

class PocketInventoryBrand extends StatelessWidget {
  final bool showTagline;
  final double markSize;

  const PocketInventoryBrand({
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
        PocketInventoryMark(size: markSize),
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
