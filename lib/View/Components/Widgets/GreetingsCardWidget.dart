import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Database/SecureStorageServices.dart';
import 'package:pocketpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:shimmer/shimmer.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: SecureStorageService().readUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(); // Less janky than loader

        final data = snapshot.data!;
        final ownerName = data['ownerName'] ?? 'Unknown Owner';
        final storeName = data['storeName'] ?? 'Your Store';

        return _GreetingCardUI(
          ownerName: ownerName,
          storeName: storeName,
        );
      },
    );
  }
}

class _GreetingCardUI extends StatelessWidget {
  final String ownerName;
  final String storeName;

  const _GreetingCardUI({
    required this.ownerName,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    final rf = context.rf;

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColor.primary, AppColor.primary.withOpacity(0.60)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _StoreIcon(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1100),
                    builder: (_, value, __) => Opacity(
                      opacity: value,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.cyanAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          "Welcome to ${storeName.isNotEmpty ? storeName : 'Your Store'}",
                          style: TextStyle(
                            fontSize: rf(12),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: AppColor.surface,
                    highlightColor: AppColor.accent,
                    period: const Duration(seconds: 3),
                    child: Text(
                      ownerName,
                      style: TextStyle(
                        fontSize: rf(16),
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Keep growing your business.",
                    style: TextStyle(
                      fontSize: rf(12),
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const _SparkleIcon(),
          ],
        ),
      ),
    );
  }
}

class _StoreIcon extends StatelessWidget {
  const _StoreIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.25),
                Colors.transparent,
              ],
              radius: 0.9,
            ),
          ),
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white.withOpacity(0.06),
          child: Spin(
            infinite: true,
            duration: const Duration(seconds: 5),
            child: Icon(
              LucideIcons.store,
              color: Colors.white,
              size: 24,
              shadows: [
                Shadow(
                  color: Colors.cyanAccent.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SparkleIcon extends StatelessWidget {
  const _SparkleIcon();

  @override
  Widget build(BuildContext context) {
    return FadeInRight(
      duration: const Duration(milliseconds: 600),
      child: Spin(
        infinite: true,
        duration: const Duration(seconds: 3),
        child: Icon(
          LucideIcons.sparkles,
          size: 22,
          color: Colors.white70,
          shadows: [
            Shadow(
              color: Colors.cyanAccent.withOpacity(0.4),
              blurRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
