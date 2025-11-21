import 'package:flutter/cupertino.dart';
import 'message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderName: 'AI Assistant',
      content: '你好！我是你的 AI 助手。有什么我可以帮你的吗？',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      id: '2',
      senderName: 'User',
      content: '我想写一个好看的 iOS 风格聊天页面。',
      isUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      id: '3',
      senderName: 'AI Assistant',
      content: '没问题！我们可以使用 Flutter 的 Cupertino 组件库来实现。',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  bool _isTyping = false;

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          senderName: 'User',
          content: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    // 模拟网络延迟后开始流式输出
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _simulateStreamingResponse();
      }
    });
  }

  void _simulateStreamingResponse() async {
    const String fullText = r"""
这是一个模拟的流式回复。

我们可以支持 Markdown 语法，比如：
- 列表项 1
- 列表项 2

**加粗文字** 和 *斜体文字*

\( f(x) = x^2 + 2x + 1 \)
""";

    // 添加初始空消息
    final aiMessageId = DateTime.now().toString();
    setState(() {
      _messages.add(
        ChatMessage(
          id: aiMessageId,
          senderName: 'AI Assistant',
          content: '',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );
    });

    // 逐字追加内容
    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      setState(() {
        final lastMsg = _messages.last;
        _messages[_messages.length - 1] = lastMsg.copyWith(
          content: fullText.substring(0, i + 1),
        );
      });
      _scrollToBottom();
    }

    // 完成流式输出
    if (mounted) {
      setState(() {
        final lastMsg = _messages.last;
        _messages[_messages.length - 1] = lastMsg.copyWith(isStreaming: false);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('AI Chat'),
        backgroundColor: Color(0xCCF9F9F9),
        border: Border(
          bottom: BorderSide(color: Color(0x4C000000), width: 0.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFFFFFFF), // 背景色
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const TypingIndicatorBubble();
                    }
                    return MessageBubble(message: _messages[index]);
                  },
                ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(
              CupertinoIcons.add,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _textController,
              focusNode: _focusNode,
              placeholder: 'iMessage',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () => _handleSubmitted(_textController.text),
            child: const Icon(
              CupertinoIcons.arrow_up_circle_fill,
              size: 32,
              color: Color(0xFF00C853),
            ),
          ),
        ],
      ),
    );
  }
}
