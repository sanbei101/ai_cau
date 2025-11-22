import 'package:flutter/cupertino.dart';
import 'message.dart';
import 'glm.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];

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
    });

    _scrollToBottom();

    _getAIResponse(text);
  }

  Future<void> _getAIResponse(String text) async {
    final aiMessageId = DateTime.now().toString();
    setState(() {
      _messages.add(
        ChatMessage(
          id: aiMessageId,
          senderName: 'CAU',
          content: '',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );
    });

    String fullContent = "";

    try {
      await for (final chunk in SimpleGLM.streamChat(content: text)) {
        if (!mounted) return;

        if (chunk.isDone) {
          break;
        }

        fullContent += chunk.content;

        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(content: fullContent);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == aiMessageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(content: "Error: $e");
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(isStreaming: false);
          }
        });
      }
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
      navigationBar: CupertinoNavigationBar(
        middle: const Text('AI Chat'),
        backgroundColor: CupertinoColors.systemBackground.withValues(
          alpha: 0.8,
        ),
        border: const Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: CupertinoColors.systemBackground,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
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
        color: CupertinoColors.secondarySystemBackground,
        border: Border(top: BorderSide(color: CupertinoColors.separator)),
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
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CupertinoColors.separator),
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
              color: CupertinoColors.activeGreen,
            ),
          ),
        ],
      ),
    );
  }
}
