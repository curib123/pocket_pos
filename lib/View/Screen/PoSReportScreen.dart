import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pocketpos/Helper/Classes_Methods/mistral_ai_helper.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';

class POSReportScreen extends StatefulWidget {
  const POSReportScreen({super.key});

  @override
  State<POSReportScreen> createState() => _POSReportScreenState();
}

class _POSReportScreenState extends State<POSReportScreen> {
  final ai = MistralAI();
  String forecastText = '';
  List<String> aiSuggestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAIReport();
  }

  Future<void> _fetchAIReport({bool retrying = false}) async {
    setState(() => isLoading = true);
    try {
      final products = context.read<ProductProvider>().getAllProductsWithVariants();
      final jsonData = products.map((e) => e.toMap()).toList();

      final responses = await Future.wait([
        ai.ask(
          options: AIRequestOptions(
            data: jsonData,
            prompt: 'Forecast next week’s sales and stock needs based on this POS data. Be concise, 2-3 lines max.',
            systemRole: 'You are a forecasting AI.',
          ),
        ),
        ai.ask(
          options: AIRequestOptions(
            data: jsonData,
            prompt: 'Give 5 smart POS business suggestions. Be brief, no explanations.',
            systemRole: 'You are a smart assistant for retail stores.',
          ),
        ),
      ]);

      final forecast = _cleanText(responses[0]);
      final suggestions = _parseLines(responses[1], 5);

      setState(() {
        forecastText = forecast;
        aiSuggestions = suggestions;
        isLoading = false;
      });

      if (forecast.isEmpty && suggestions.isEmpty && !retrying) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No AI response. Retrying...')),
        );
        await Future.delayed(const Duration(seconds: 2));
        _fetchAIReport(retrying: true);
      }
    } catch (e) {
      debugPrint('⚠️ AI Report Error: $e');
      setState(() => isLoading = false);
    }
  }

  String _cleanText(String input) {
    return input.replaceAll(RegExp(r'[*_\-#`~>]'), '').trim();
  }

  List<String> _parseLines(String raw, int limit) {
    return raw
        .trim()
        .split('\n')
        .map((e) => _cleanText(e))
        .where((e) => e.isNotEmpty)
        .take(limit)
        .toList();
  }

  void _copyToClipboard(String text, {String label = 'Copied!'}) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), duration: const Duration(milliseconds: 1000)),
    );
  }

  Widget _shimmerBox({double height = 60}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildForecastBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(LucideIcons.lineChart, "AI Forecast"),
          const SizedBox(height: 10),
          isLoading
              ? _shimmerBox(height: 80)
              : GestureDetector(
            onLongPress: () {
              if (forecastText.isNotEmpty) {
                _copyToClipboard(forecastText, label: 'Forecast copied!');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                forecastText.isNotEmpty ? forecastText : "No forecast available.",
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(LucideIcons.sparkles, "Smart Suggestions"),
          const SizedBox(height: 10),
          isLoading
              ? Column(
            children: List.generate(
              5,
                  (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _shimmerBox(height: 16),
              ),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: aiSuggestions.isNotEmpty
                ? aiSuggestions.map((s) {
              return GestureDetector(
                onLongPress: () => _copyToClipboard(s, label: 'Suggestion copied!'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()
                : [
              Text(
                "No suggestions available.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("AI POS Report", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAIReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildForecastBox(),
              _buildSuggestionBox(),
            ],
          ),
        ),
      ),
    );
  }
}
