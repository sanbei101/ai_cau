import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
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

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  Future<void> callGLMStream(String userText) async {
    final String aiMessageId = '${Random().nextInt(100000)}';

    var currentAiMessage = TextMessage(
      id: aiMessageId,
      authorId: aiUserId,
      createdAt: DateTime.now().toUtc(),
      text: "🤔 思考中...",
    );

    chatController.insertMessage(currentAiMessage);

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

        final newAiMessage = TextMessage(
          id: aiMessageId,
          authorId: aiUserId,
          createdAt: DateTime.now().toUtc(),
          text: displayUserText,
        );

        chatController.updateMessage(currentAiMessage, newAiMessage);
        currentAiMessage = newAiMessage;
      }
    } catch (e) {
      final errorMessage = TextMessage(
        id: aiMessageId,
        authorId: aiUserId,
        createdAt: DateTime.now().toUtc(),
        text: "❌ 出错了: $e",
      );
      chatController.updateMessage(currentAiMessage, errorMessage);
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
