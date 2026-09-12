import 'package:flutter_deepseek/flutter_deepseek.dart';

class AIService {
  final DeepSeekClient _client;

  AIService({required String apiKey})
      : _client = DeepSeekClient(apiKey: apiKey);

  /// 流式生成内容（打字机效果）
  Stream<String> generateStory(List<String> words) {
    final prompt = '''
    帮我用这些单词编一个容易记住的英文小段子：${words.join('、')}
    
    要求：
    1. 段子用英文写，只需要一个就行
    2. 段子后面用括号给出中文翻译
    3. 最好包含谐音梗、联想、或与单词发音/拼写相关的记忆点
    4. 内容要幽默、有趣、容易记住
    5. 输出的内容不要包含那些星号样式的引号，输出看起来要通顺
    ''';

    return _client.chatStream(
      messages: [
        ChatMessage.system(
            '你是一个专业的英语学习助手，擅长用谐音、联想、趣味故事帮助用户记单词。'
        ),
        ChatMessage.user(prompt),
      ],
    );
  }

  void dispose() {
    _client.dispose();
  }
}