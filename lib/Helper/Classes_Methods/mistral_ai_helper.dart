import 'dart:convert';
import 'package:http/http.dart' as http;

/// 👨‍🔧 Mistral AI Configuration
class AIRequestOptions {
  final String prompt;
  final dynamic data;
  final String systemRole;
  final double temperature;
  final String model;
  final int chunkSize;
  final String? customUserPrompt;

  AIRequestOptions({
    required this.prompt,
    this.data,
    this.systemRole = 'You are a helpful assistant.',
    this.temperature = 0.7,
    this.model = 'mistral-medium',
    this.chunkSize = 50,
    this.customUserPrompt,
  });
}

/// 🧠 Mistral AI Class
class MistralAI {
  final String _apiKey = 'TZjSrnSAjyflYyNyFmPnMfHHSZ4Mw33q';
  final String _apiUrl = 'https://api.mistral.ai/v1/chat/completions';

  /// 🔁 Auto-chunking + summary
  Future<String> ask({
    required AIRequestOptions options,
  }) async {
    List<dynamic> chunks = [];

    if (options.data is List) {
      final List dataList = options.data;
      for (int i = 0; i < dataList.length; i += options.chunkSize) {
        chunks.add(dataList.sublist(
          i,
          i + options.chunkSize > dataList.length ? dataList.length : i + options.chunkSize,
        ));
      }
    } else if (options.data != null) {
      chunks = [options.data];
    } else {
      chunks = [[]];
    }

    List<String> chunkSummaries = [];

    for (var chunk in chunks) {
      // ✅ Use customUserPrompt if explicitly provided
      final promptWithChunk = options.customUserPrompt != null
          ? options.customUserPrompt!
          : '''
${options.prompt}
${options.data != null ? '\n\nContext data:\n${jsonEncode(chunk)}' : ''}
''';

      final res = await _sendRequest(
        model: options.model,
        temperature: options.temperature,
        systemRole: options.systemRole,
        userPrompt: promptWithChunk,
      );

      chunkSummaries.add(res);
    }

    // 🧠 Combine multiple chunk summaries if needed
    if (chunkSummaries.length == 1) {
      return chunkSummaries.first;
    } else {
      final mergedSummary = await _sendRequest(
        model: options.model,
        temperature: options.temperature,
        systemRole: options.systemRole,
        userPrompt: '''
Combine and summarize the following insights from multiple chunks:\n\n${chunkSummaries.join("\n\n")}
''',
      );
      return mergedSummary;
    }
  }

  /// 🚀 Call Mistral API with a user prompt
  Future<String> _sendRequest({
    required String model,
    required double temperature,
    required String systemRole,
    required String userPrompt,
  }) async {
    final body = jsonEncode({
      'model': model,
      'temperature': temperature,
      'messages': [
        {"role": "system", "content": systemRole},
        {"role": "user", "content": userPrompt},
      ],
    });

    final res = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (res.statusCode == 200) {
      final responseJson = jsonDecode(res.body);
      return responseJson['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('🧨 Mistral API error: ${res.statusCode}\n${res.body}');
    }
  }
}
