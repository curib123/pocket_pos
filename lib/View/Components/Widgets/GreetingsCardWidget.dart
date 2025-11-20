import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nextpos/Helper/Database/PurchaseService.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Helper/Database/SecureStorageServices.dart';
import 'package:nextpos/View/Components/Widgets/ResponsiveText.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorageService();
    final purchase = PurchaseService();

    return FutureBuilder<Map<String, String?>>(
      future: storage.readUser(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox();

        final data = userSnapshot.data!;
        final ownerName = data['ownerName'] ?? 'Unknown Owner';
        final storeName = data['storeName'] ?? 'Your Store';

        return FutureBuilder<DateTime?>(
          future: storage.readTrialExpirationDate(),
          builder: (context, trialSnapshot) {
            if (trialSnapshot.connectionState != ConnectionState.done) {
              return const SizedBox();
            }

            final now = DateTime.now();
            String trialMessage = '';
            bool isExpired = false;

            if (trialSnapshot.hasData && trialSnapshot.data != null) {
              final expirationDate = trialSnapshot.data!;
              isExpired = now.isAfter(expirationDate);
              final formattedDate =
                  "${expirationDate.month}/${expirationDate.day}/${expirationDate.year}";

              trialMessage = isExpired
                  ? "⛔ Your free trial expired on $formattedDate"
                  : "✅ Your trial is active until $formattedDate";
            }

            return FutureBuilder<bool>(
              future: purchase.getTrial(),
              builder: (context, trialStatusSnapshot) {
                final shouldShowTrial = trialStatusSnapshot.data ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingCardUI(
                      ownerName: ownerName,
                      storeName: storeName,
                    ),
                    if (trialMessage.isNotEmpty && shouldShowTrial) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.withOpacity(0.85),
                                Colors.blueAccent.withOpacity(0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.clock4,
                                size: 20,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  trialMessage,
                                  style: TextStyle(
                                    fontSize: context.rf(12),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
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
            colors: [
              Colors.indigo.withOpacity(0.85),
              Colors.blueAccent.withOpacity(0.75),
            ],
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
