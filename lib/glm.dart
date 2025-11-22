import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

class GLMChunk {
  final String content;
  final String reasoning;
  final bool isDone;

  GLMChunk({this.content = "", this.reasoning = "", this.isDone = false});
}

class SimpleGLM {
  static String baseUrl = "https://open.bigmodel.cn/api/paas/v4";
  static String apiKey = "b6c3ce3004ce4b699fd27dc65d14f632.dXVJQ3hochLTB0ks";

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.stream,
    ),
  );

  static Stream<GLMChunk> streamChat({
    required String content,
    String model = "glm-4-flash",
  }) async* {
    if (apiKey.isEmpty) throw Exception("请先设置 SimpleGLM.apiKey");

    final url = "$baseUrl/chat/completions";
    final data = {
      "model": model,
      "messages": [
        {"role": "user", "content": content},
      ],
      "stream": true,
      "temperature": 0.7,
    };

    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      final stream = response.data.stream;

      String buffer = "";

      await for (final List<int> bytes in stream) {
        final chunk = utf8.decode(bytes);
        buffer += chunk;

        while (buffer.contains("\n")) {
          final index = buffer.indexOf("\n");
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.startsWith("data:")) {
            final jsonStr = line.substring(5).trim();

            if (jsonStr == "[DONE]") {
              yield GLMChunk(isDone: true);
              return;
            }

            try {
              final Map<String, dynamic> json = jsonDecode(jsonStr);
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'];

                final contentDelta = delta['content']?.toString() ?? "";
                final reasoningDelta =
                    delta['reasoning_content']?.toString() ?? "";

                if (contentDelta.isNotEmpty || reasoningDelta.isNotEmpty) {
                  yield GLMChunk(
                    content: contentDelta,
                    reasoning: reasoningDelta,
                  );
                }
              }
            } catch (e) {
              // ignore: avoid_print
              print("JSON Parse Error: $e");
            }
          }
        }
      }
    } on DioException catch (e) {
      // ignore: avoid_print
      print("Dio Error: ${e.message}");
      if (e.response != null) {
        print("Server Response: ${e.response?.data}");
      }
      throw Exception("流式请求失败: ${e.message}\n详细信息: ${e.response?.data}");
    }
  }
}
