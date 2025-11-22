import 'dart:math';
import 'package:flutter/cupertino.dart';
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

  final ValueNotifier<String>? contentNotifier;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.avatarUrl,
    this.isStreaming = false,
    this.contentNotifier,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    ValueNotifier<String>? contentNotifier,
  }) {
    return ChatMessage(
      id: id,
      senderName: senderName,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      avatarUrl: avatarUrl,
      isStreaming: isStreaming ?? this.isStreaming,
      contentNotifier: contentNotifier ?? this.contentNotifier,
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
    final bool isTypingState =
        message.isStreaming &&
        message.content.isEmpty &&
        message.contentNotifier == null;

    if (isTypingState) {
      return _buildTypingIndicator(context);
    } else {
      return _buildTextBubble(context);
    }
  }

  Widget _buildTextBubble(BuildContext context) {
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? CupertinoColors.systemGreen.resolveFrom(context)
        : CupertinoColors.systemGrey5.resolveFrom(context);

    final textColor = isUser
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);

    final markdownStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      height: 1.4,
    );

    Widget contentWidget;

    if (message.contentNotifier != null) {
      contentWidget = ValueListenableBuilder<String>(
        valueListenable: message.contentNotifier!,
        builder: (context, value, child) {
          return GptMarkdown('$value ▍', style: markdownStyle);
        },
      );
    } else {
      contentWidget = GptMarkdown(message.content, style: markdownStyle);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser && showAvatar) ...[
                _buildAvatar(context),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  child: contentWidget,
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
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showAvatar) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 32.0 + 8.0),
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _TypingDotsAnimation(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: CupertinoColors.secondarySystemFill.resolveFrom(context),
      child: message.avatarUrl == null
          ? Text(
              message.senderName.substring(0, 1),
              style: TextStyle(
                color: CupertinoColors.systemBlue.resolveFrom(context),
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class _TypingDotsAnimation extends StatefulWidget {
  const _TypingDotsAnimation();

  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
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
    return SizedBox(
      width: 26,
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = (_controller.value + index * 0.2) % 1.0;
              final double opacity = (sin(t * pi * 2) + 1) / 2;
              return Opacity(
                opacity: 0.3 + (opacity * 0.7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
