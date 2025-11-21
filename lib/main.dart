import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'glm.dart';

void main() {
  SimpleGLM.apiKey = "b6c3ce3004ce4b699fd27dc65d14f632.dXVJQ3hochLTB0ks";
  runApp(
    const MaterialApp(
      title: 'CAU AI',
      home: ChatPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final String currentUserId = 'user1';
  final String aiUserId = 'glm_ai';
  final chatController = InMemoryChatController();
  final Map<String, StreamState> _streamStates = {};

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  Future<void> callGLMStream(String userText) async {
    final String aiMessageId = '${Random().nextInt(100000)}';

    final streamMessage = TextStreamMessage(
      id: aiMessageId,
      authorId: aiUserId,
      createdAt: DateTime.now().toUtc(),
      streamId: aiMessageId,
    );

    chatController.insertMessage(streamMessage);

    setState(() {
      _streamStates[aiMessageId] = const StreamStateLoading();
    });

    String fullReasoning = "";
    String fullContent = "";

    try {
      final stream = SimpleGLM.streamChat(
        content: userText,
        model: "glm-4.5-flash",
      );

      await for (final chunk in stream) {
        if (chunk.isDone) break;

        fullReasoning += chunk.reasoning;
        fullContent += chunk.content;

        String displayUserText = "";
        if (fullReasoning.isNotEmpty) {
          displayUserText += "> **深度思考**\n";
          final reasoningLines = fullReasoning.split('\n');
          for (var line in reasoningLines) {
            displayUserText += "> $line\n";
          }
          displayUserText += "\n---\n";
        }
        displayUserText += fullContent;

        setState(() {
          _streamStates[aiMessageId] = StreamStateStreaming(displayUserText);
        });
      }

      final finalState = _streamStates[aiMessageId];
      String finalText = "无内容";
      if (finalState is StreamStateStreaming) {
        finalText = finalState.accumulatedText;
      } else if (finalState is StreamStateCompleted) {
        finalText = finalState.finalText;
      }

      final finalMessage = TextMessage(
        id: aiMessageId,
        authorId: aiUserId,
        createdAt: DateTime.now().toUtc(),
        text: finalText,
      );

      chatController.updateMessage(streamMessage, finalMessage);

      setState(() {
        _streamStates.remove(aiMessageId);
      });
    } catch (e) {
      final errorMessage = TextMessage(
        id: aiMessageId,
        authorId: aiUserId,
        createdAt: DateTime.now().toUtc(),
        text: "❌ 出错了: $e",
      );
      chatController.updateMessage(streamMessage, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GLM Thinking Stream")),
      body: Chat(
        currentUserId: currentUserId,
        resolveUser: (id) async =>
            User(id: id, name: id == aiUserId ? "GLM" : "Me"),
        chatController: chatController,
        builders: Builders(
          textStreamMessageBuilder:
              (context, message, index, {required isSentByMe, groupStatus}) {
                final state =
                    _streamStates[message.streamId] ??
                    const StreamStateLoading();

                return FlyerChatTextStreamMessage(
                  message: message,
                  streamState: state,
                  index: index,
                  mode: TextStreamMessageMode.instantMarkdown,
                );
              },
          textMessageBuilder:
              (context, message, index, {required isSentByMe, groupStatus}) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.blue : const Color(0xfff5f5f5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GptMarkdown(
                    message.text,
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
        ),
        onMessageSend: (text) {
          chatController.insertMessage(
            TextMessage(
              id: '${Random().nextInt(1000)}',
              authorId: currentUserId,
              createdAt: DateTime.now().toUtc(),
              text: text,
            ),
          );
          callGLMStream(text);
        },
      ),
    );
  }
}
