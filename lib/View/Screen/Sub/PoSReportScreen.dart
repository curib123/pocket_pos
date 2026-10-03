
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nextpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:nextpos/Helper/Classes_Methods/mistral_ai_helper.dart';
import 'package:nextpos/Provider/ProductProvider.dart';

class POSReportScreen extends StatefulWidget {
  const POSReportScreen({super.key});

  @override
  State<POSReportScreen> createState() => _POSReportScreenState();
}

class _POSReportScreenState extends State<POSReportScreen> {
  final ai = MistralAI();
  String reportSummary = '';
  List<String> aiSuggestions = [];
  String timestamp = '';
  bool isLoading = true;
  String _selectedRange = "Today";

  @override
  void initState() {
    super.initState();
    _fetchAIReport();
  }

  Future<void> _fetchAIReport({bool retrying = false}) async {
    setState(() {
      isLoading = true;
      timestamp = '';
    });

    try {
      final products = context.read<ProductProvider>().getAllProductsWithVariants();
      final jsonData = products.map((e) => e.toMap()).toList();

      final responses = await Future.wait([
        ai.ask(
          options: AIRequestOptions(
            model: "mistral-small",
            data: jsonData,
            prompt: 'Generate a short POS report summarizing recent product sales, top movers, and stock usage patterns. Keep it within 2-3 lines.',
            systemRole: 'You are a POS analytics assistant.',
          ),
        ),
        ai.ask(
          options: AIRequestOptions(
            model: "mistral-small",
            data: jsonData,
            prompt: 'List 5 smart product-related business suggestions based on this POS data. No explanations, just brief points.',
            systemRole: 'You are a POS retail strategist.',
          ),
        ),
      ]).timeout(const Duration(seconds: 10));


      final summary = _cleanText(responses[0]);
      final suggestions = _parseLines(responses[1], 5);

      final isEmpty = summary.isEmpty && suggestions.isEmpty;

      if (isEmpty && !retrying) {
        // Retry once after 1 second if response is empty
        await Future.delayed(const Duration(seconds: 1));
        return _fetchAIReport(retrying: true);
      }

      setState(() {
        reportSummary = summary;
        aiSuggestions = suggestions;
        isLoading = false;
        timestamp = DateFormat('MMM d, y – hh:mm a').format(DateTime.now());
      });
    } catch (e) {
      debugPrint('⚠️ AI Report Error: $e');
      if (!retrying) {
        await Future.delayed(const Duration(seconds: 1));
        return _fetchAIReport(retrying: true);
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate AI report.')),
      );
    }
  }


  String _cleanText(String input) =>
      input.replaceAll(RegExp(r'[*_\-#`~>]'), '').trim();

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
      SnackBar(content: Text(label), duration: const Duration(milliseconds: 800)),
    );
  }

  Widget _shimmerBox({double height = 60}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.white,
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
    return Shimmer.fromColors(
      baseColor: Colors.black87,
      highlightColor: Colors.deepPurple.shade100,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _frostedGlass({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReportBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(LucideIcons.fileText, "AI Report Summary"),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? _shimmerBox(height: 80)
                : GestureDetector(
              onLongPress: () => _copyToClipboard(reportSummary, label: 'Summary copied!'),
              child: _frostedGlass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportSummary.isNotEmpty ? reportSummary : "No report summary available.",
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    if (timestamp.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text("Generated on $timestamp",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
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
            children: List.generate(5, (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _shimmerBox(height: 16),
            )),
          )
              : aiSuggestions.isNotEmpty
              ? _frostedGlass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...aiSuggestions.map(
                      (s) => GestureDetector(
                    onLongPress: () => _copyToClipboard(s, label: 'Suggestion copied!'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.circle, size: 6, color: Colors.black54),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _copyToClipboard(aiSuggestions.join('\n'), label: "All suggestions copied!"),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text("Copy All"),
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildRangeSelectorDropdown() {
    final options = ['Today', 'This Week', 'This Month', 'All Time'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CustomFlatDropdown<String>(
        hint: 'Select range',
        prefixIcon: Icons.calendar_today,
        value: _selectedRange,
        items: options,
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedRange = val);
            _fetchAIReport(); // still refetches on change
          }
        },
        itemBuilder: (val) => Text(val),
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
        elevation: 1,
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
              _buildRangeSelectorDropdown(),
              _buildReportBox(),
              _buildSuggestionBox(),
            ],
          ),
        ),
      ),
    );
  }
}
