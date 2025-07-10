import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:provider/provider.dart';

Widget buildGreetingCard(String ownerName,String storeName) {
  return Consumer<AuthPaymentProvider>(
    builder: (context, authPaymentProvider, child) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: authPaymentProvider.getTrialInfoOffline(),
        builder: (context, snapshot) {
          final trialInfo = snapshot.data;

          return Column(
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        AppColor.primary.withOpacity(0.8),
                        AppColor.primary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.cyanAccent.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            child: Spin(
                              infinite: true,
                              duration: const Duration(seconds: 5),
                              child: Icon(
                                LucideIcons.store,
                                color: Colors.white,
                                size: 30,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyanAccent.withOpacity(0.6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOut,
                              builder: (context, value, child) => Opacity(
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
                                    "Welcome to ${storeName ?? 'Your Store'}",
                                    style: TextStyle(
                                      fontSize: getResponsiveFontSize(context, 12),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ownerName ?? 'Unknown Owner',
                              style: TextStyle(
                                fontSize: getResponsiveFontSize(context, 16),
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Keep growing your business today.",
                              style: TextStyle(
                                fontSize: getResponsiveFontSize(context, 11),
                                color: Colors.white.withOpacity(0.75),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FadeInRight(
                        duration: const Duration(milliseconds: 800),
                        child: Spin(
                          infinite: true,
                          duration: const Duration(seconds: 4),
                          child: Icon(
                            LucideIcons.sparkles,
                            size: 26,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                color: Colors.cyanAccent.withOpacity(0.5),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.done &&
                  trialInfo != null &&
                  trialInfo['isTrial'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "🎁 You’re enjoying a Free Trial — ${trialInfo['remainingDays']} day(s) left!\nUnlock lifetime access anytime to keep your progress safe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 11),
                      color: AppColor.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}