import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/mistral_ai_helper.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:provider/provider.dart';

class POSChatScreen extends StatefulWidget {
  const POSChatScreen({super.key});

  @override
  State<POSChatScreen> createState() => _POSChatScreenState();
}

class _POSChatScreenState extends State<POSChatScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool waitingForResponse = false;
  bool loadingSuggestions = true;

  late final AnimationController _dotsController;
  late final Animation<int> _dotCount;
  late final MistralAI ai;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ai = MistralAI();
    _dotsController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _dotCount = StepTween(begin: 1, end: 3).animate(_dotsController);

    Future.microtask(() {
      final productProvider = context.read<ProductProvider>();
      _loadAISuggestions(productProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dotsController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getProductJson(ProductProvider provider) async {
    return provider.getAllProductsWithVariants().map((p) => p.toMap()).toList();
  }

  Future<void> _loadAISuggestions(ProductProvider productProvider) async {
    setState(() {
      loadingSuggestions = true;
      messages.removeWhere((msg) => msg["content"] == "suggestions");
    });

    try {
      final jsonData = await _getProductJson(productProvider);
      final response = await ai.ask(
        options: AIRequestOptions(
          data: jsonData,
          prompt: '''
You are a professional sales strategist analyzing POS data.
Based on the provided product data, generate 3 actionable sales suggestions or strategic questions.
Focus on stock movement, pricing, bundling, and sales opportunities.
Keep it concise. No explanations.
''',
          systemRole: 'You are a fintech AI assistant specialized in POS optimization, sales strategy, and forecasting.',

        ),
      );

      final suggestions = response
          .split(RegExp(r'[\n•\-]'))
          .map((s) => s.replaceAll(RegExp(r'[^\w\s,.!?]'), '').trim())
          .where((s) => s.isNotEmpty)
          .take(5)
          .toList();

      setState(() {
        messages.add({
          "role": "ai",
          "content": "suggestions",
          "suggestions": suggestions,
        });
        loadingSuggestions = false;
      });
    } catch (e) {
      debugPrint("Suggestions error: $e");
      setState(() => loadingSuggestions = false);
    }

    _scrollToBottom();
  }

  Future<void> _sendMessage(String text, ProductProvider productProvider) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": text});
      waitingForResponse = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final jsonData = await _getProductJson(productProvider);
      final reply = await ai.ask(
        options: AIRequestOptions(
          data: jsonData,
          prompt: text,
          systemRole: 'You are a helpful POS assistant. Respond clearly and briefly.',
        ),
      );

      final cleanedReply = reply.replaceAll(RegExp(r'[^\w\s,.!?]'), '').trim();

      setState(() {
        messages.add({"role": "ai", "content": cleanedReply});
        waitingForResponse = false;
      });
    } catch (e) {
      debugPrint("AI error: $e");
      setState(() {
        messages.add({"role": "ai", "content": "⚠️ Oops, something went wrong!"});
        waitingForResponse = false;
      });
    }

    _scrollToBottom();
  }

  Widget _buildDotLoader() {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) =>
          Text("..." * _dotCount.value, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg, ProductProvider productProvider) {
    final isUser = msg["role"] == "user";

    if (msg["content"] == "suggestions" && msg["suggestions"] is List) {
      final suggestions = msg["suggestions"] as List<String>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("💡 Suggestions:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((s) {
                  return ActionChip(
                    avatar: const Icon(LucideIcons.sparkles, size: 14),
                    label: Text(s, style: const TextStyle(fontSize: 13)),
                    backgroundColor: AppColor.secondarySurface,
                    side: const BorderSide(color: AppColor.accent, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendMessage(s, productProvider),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColor.primary.withOpacity(0.15) : AppColor.secondarySurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        child: Text(msg["content"], style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildBottomInput(ProductProvider productProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _loadAISuggestions(productProvider);
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Type your question...",
                  border: InputBorder.none,
                ),
                onSubmitted: (text) => _sendMessage(text, productProvider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.send),
            onPressed: () => _sendMessage(_controller.text, productProvider),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Chat Assistant"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          return Column(
            children: [
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length +
                      (loadingSuggestions ? 1 : 0) +
                      (waitingForResponse ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColor.secondarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                loadingSuggestions ? "Loading suggestions" : "Thinking",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildDotLoader(),
                            ],
                          ),
                        ),
                      );
                    }

                    return _buildMessage(messages[index], productProvider);
                  },
                ),
              ),
              const Divider(height: 1),
              _buildBottomInput(productProvider),
            ],
          );
        },
      ),
    );
  }
}
