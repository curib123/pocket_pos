import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Helper/Classes_Methods/mistral_ai_helper.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';

class AISnackbarManager {
  static final _ai = MistralAI();

  static Future<void> showAIAlert(
      BuildContext context, {
        required String screenName,
      }) async {
    try {
      final products = context.read<ProductProvider>().getAllProductsWithVariants();
      final data = products.map((e) => e.toMap()).toList();

      final response = await _ai.ask(
        options: AIRequestOptions(
          prompt: '''
Analyze the stock data and return one short actionable insight for the $screenName screen. 
Focus on low stock, fast-moving, overstocked, or inactive items. 
Keep it under 15 words. Avoid quotes and special characters. End with a status tag like [status: good], [status: bad], or [status: neutral].
Example: Low stock on 5 fast-selling items. [status: bad]
''',
          data: data,
        ),
      );

      if (!context.mounted) return;

      final moodMatch = RegExp(r'\[status: (good|bad|neutral)\]').firstMatch(response);
      final mood = moodMatch?.group(1) ?? 'neutral';
      final cleanMessage = response.replaceAll(RegExp(r'\[status: (good|bad|neutral)\]'), '').trim();

      final moodStyles = <String, (Color, IconData)>{
        'good': (AppColor.primary, LucideIcons.checkCircle),
        'bad': (AppColor.errorText, LucideIcons.alertTriangle),
        'neutral': (AppColor.accent, LucideIcons.info),
      };

      final (bgColor, icon) = moodStyles[mood]!;

      final overlay = Overlay.of(context);
      final entry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cleanMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      await Future.delayed(const Duration(seconds: 4));
      entry.remove();
    } catch (e) {
      debugPrint('AI Alert Error: $e');
    }
  }
}
