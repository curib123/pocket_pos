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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool waitingForResponse = false;
  bool loadingSuggestions = true;

  late final AnimationController _dotsController;
  late final Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAISuggestions(context.read<ProductProvider>());

    _dotsController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _dotCount = StepTween(begin: 1, end: 3).animate(_dotsController);
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
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadAISuggestions(ProductProvider productProvider) async {
    setState(() {
      loadingSuggestions = true;
      messages.removeWhere((msg) => msg["content"] == "suggestions");
    });

    try {
      final allProducts = productProvider.getAllProductsWithVariants();
      final jsonData = allProducts.map((p) => p.toMap()).toList();
      final ai = MistralAI();
      final result = await ai.ask(
        options: AIRequestOptions(
          data: jsonData,
          prompt: '''
You are a POS analytics assistant.

Based on the provided product data (including name, stock, sold quantity, price, and recent sales), do the following:
- Analyze overall stock health and performance trends.
- Suggest metrics like top sellers, low stock alerts, or unsold products.
- Predict which products may run out soon or are trending.
- Recommend what insights the user should ask next.

Return only a clean bullet list of 5 smart suggestions (like questions the user can ask), no titles or explanations.
''',
          systemRole: 'You are a fintech AI assistant specialized in POS analytics and forecasting.',
        ),
      );

      final extracted = result
          .split(RegExp(r'[\n•-]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();

      setState(() {
        messages.add({
          "role": "ai",
          "content": "suggestions",
          "suggestions": extracted,
        });
        loadingSuggestions = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("Suggestion error: $e");
      setState(() {
        loadingSuggestions = false;
      });
    }
  }

  Future<void> _sendMessage(String content, ProductProvider productProvider) async {
    if (content.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": content});
      waitingForResponse = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final allProducts = productProvider.getAllProductsWithVariants();
      final jsonData = allProducts.map((p) => p.toMap()).toList();
      final ai = MistralAI();
      final response = await ai.ask(
        options: AIRequestOptions(
          data: jsonData,
          prompt: content,
          systemRole: 'You are a helpful POS assistant. Respond clearly and briefly.',
        ),
      );

      setState(() {
        messages.add({"role": "ai", "content": response});
        waitingForResponse = false;
      });
    } catch (e) {
      debugPrint("AI response error: $e");
      setState(() {
        messages.add({
          "role": "ai",
          "content": "⚠️ Something went wrong. Please try again!",
        });
        waitingForResponse = false;
      });
    }

    _scrollToBottom();
  }

  Widget _buildDotLoader() {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        String dots = '.' * _dotCount.value;
        return Text("Thinking$dots", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic));
      },
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg, ProductProvider productProvider) {
    final isUser = msg["role"] == "user";

    if (msg["content"] == "suggestions" && msg["suggestions"] is List) {
      final suggestions = msg["suggestions"] as List<String>;
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("💡 Suggested questions:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 13)),
                  backgroundColor: Colors.grey.shade200,
                  onPressed: () => _sendMessage(s, productProvider),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColor.primary.withOpacity(0.2) :  AppColor.secondarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg["content"], style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("POS Chat Assistant"),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new),
        ),
        elevation: 0,
      ),
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
                      if (loadingSuggestions) {
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
                                const Text("Loading suggestions", style: TextStyle(fontSize: 14,color: AppColor.textSecondary)),
                                const SizedBox(width: 6),
                                _buildDotLoader(),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColor.secondarySurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildDotLoader(),
                          ),
                        );
                      }
                    }

                    return _buildMessage(messages[index], productProvider);
                  },
                ),
              ),
              const Divider(height: 1),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Ask anything...",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (text) => _sendMessage(text, productProvider),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.send),
                      onPressed: () => _sendMessage(_controller.text, productProvider),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
