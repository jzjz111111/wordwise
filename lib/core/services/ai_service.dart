import 'dart:convert';
import 'package:dio/dio.dart';

/// AI 服务：对接阿里云百炼平台（千问/DeepSeek 兼容模式）

class AIService {
  final Dio _dio;
  final String model;

  /// baseUrl 固定用阿里云百炼的 OpenAI 兼容端点
  static const String _baseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';

  AIService({
    required String apiKey,
    this.model = 'deepseek-v4.1-flash-1017',
  }) : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 60),
          connectTimeout: const Duration(seconds: 15),
        ));

  /// 流式生成助记内容（打字机效果）
  Stream<String> generateMemory({
    required List<String> words,
    String promptType = 'per_word', // 'per_word' | 'story' | 'root_cluster'
  }) async* {
    final prompt = _buildPrompt(words, promptType);

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'stream': true,
        'messages': [
          {
            'role': 'system',
            'content':
                '你是一个专业的英语单词记忆专家，擅长用拆解、联想、场景画面帮助用户记住难词。'
          },
          {'role': 'user', 'content': prompt},
        ],
      },
      options: Options(responseType: ResponseType.stream),
    );

    // SSE 流式解析：阿里云百炼和 OpenAI 一样，返回 text/event-stream
    //
    // 注意：response.data.stream 是 UTF-8 字节流，必须用 utf8.decoder 解码，
    // 不能用 String.fromCharCodes（它把字节当码元，中文会变乱码）。
    // 网络分片还可能把多字节字符或一整行 JSON 从中间切断，所以需要 buffer 攒完整的行。
    final textStream =
        response.data.stream.cast<List<int>>().transform(utf8.decoder);

    var buffer = '';

    await for (final text in textStream) {
      buffer += text;

      int newlineIndex;
      while ((newlineIndex = buffer.indexOf('\n')) != -1) {
        final rawLine = buffer.substring(0, newlineIndex);
        buffer = buffer.substring(newlineIndex + 1);

        final trimmed = rawLine.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;

        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List;
          if (choices.isEmpty) continue;
          final delta = choices.first['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null) yield content;
        } catch (_) {
          // 忽略解析失败的片段
        }
      }
    }
  }

  /// 构建提示词
  String _buildPrompt(List<String> words, String type) {
    final wordList = words.join('、');

    switch (type) {
      case 'story':
        return '''
帮我用这些单词编一个有主题的英文小故事：$wordList

要求：
1. 先给故事定一个场景主题（图书馆/机场/面试等，选最适合的）
2. 故事英文写，150-200 词，有完整情节
3. 每个目标单词出现时右上角加 ①②③... 上标
4. 故事后按编号列出每个单词的中文含义 + 记忆点
5. 最后给故事中文翻译
''';

      case 'root_cluster':
        return '''
分析以下单词，找出共同的词根/词缀/语义场，聚类帮助记忆：$wordList

要求：
1. 先扫描，找出共同词根（如 port=携带、struct=建造、dict=说）
2. 如果有共同词根 → 先讲词根故事，再把相关单词排在一起
3. 如果没有共同词根 → 退回到逐个击破模式（方案 A）
4. 语言生动像老师讲课，不是冷冰冰词典
''';

      case 'per_word':
      default:
        return '''
请为以下每个单词提供最适合它的助记方法：$wordList

输出格式（每个单词都要这样）：

═══════════════════════
📖 单词：[词] /[音标]/
📌 词义：[中文]

🔍 拆解：[词根词缀拆解 或 拼写拆分]
🎵 联想：[谐音/场景画面/记忆钩子，一句话]
📝 例句：[英文常用例句]（[中文翻译]）
═══════════════════════

规则：
- 助记方法灵活选：合成词→拆解，发音像中文→谐音，能拆成熟悉词→拼写联想，其他→场景画面
- 例句真实常用，优先四六级/考研真题例句
- 精炼不啰嗦，每个单词 3-4 行
''';
    }
  }

  void dispose() {
    _dio.close();
  }
}
