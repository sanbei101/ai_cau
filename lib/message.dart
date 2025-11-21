import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class ChatMessage {
  final String id;
  final String senderName;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? avatarUrl;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.avatarUrl,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? content, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      senderName: senderName,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      avatarUrl: avatarUrl,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? const Color(0xFF00C853)
        : const Color(0xFFE0E0E0);

    final textColor = isUser ? Colors.white : Colors.black87;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48.0, bottom: 4.0),
              child: Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser && showAvatar) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],

              // 气泡本体
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    // MessageKit 风格圆角：根据发送者方向调整
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(
                        isUser ? 20 : 4,
                      ), // 对方的消息左下角是尖的
                      bottomRight: Radius.circular(
                        isUser ? 4 : 20,
                      ), // 用户的消息右下角是尖的
                    ),
                  ),
                  child: GptMarkdown(
                    message.isStreaming
                        ? '${message.content} ▍'
                        : message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4.0,
              right: isUser ? 0 : 0,
              left: isUser ? 0 : 48,
            ),
            child: Text(
              isUser ? "Delivered" : _formatTime(message.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.purple[100],
      child: message.avatarUrl == null
          ? Text(
              message.senderName.substring(0, 1),
              style: const TextStyle(color: Colors.purple),
            )
          : null,
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 占位头像，保持对齐
          const SizedBox(width: 32 + 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SizedBox(
              width: 40,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final double t = (_controller.value + index / 3) % 1.0;
                      final double opacity = (sin(t * pi * 2) + 1) / 2;
                      return Opacity(
                        opacity: 0.3 + (opacity * 0.7),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
