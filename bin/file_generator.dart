import 'dart:async';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';

import 'progress_bar.dart';
import 'query_options.dart';

void main() async {
  final progressBar = ProgressBar();

  progressBar.run();
  await runSchedule(directoryName: 'input');
  progressBar.stop();

  stdout.write('Готово! Проверьте output');
  exit(0);
}

Future<String> sendRequestToChatGPT(String query) async {
  OpenAI.apiKey = QueryOptions.apiKey;
  OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
    model: "gpt-3.5-turbo",
    messages: [
      OpenAIChatCompletionChoiceMessageModel(
        content: '${QueryOptions.templateQuery} Задача - $query',
        role: OpenAIChatMessageRole.user,
      ),
    ],
  );
  return chatCompletion.choices.first.message.content;
}

Future<void> runSchedule({required String directoryName}) async {
  try {
    final templateFile = File('template.txt');
    final directory = Directory(directoryName);
    String templateQuery = '';
    int queryCounter = 0;

    templateFile.readAsString().then((String contents) {
      templateQuery = contents;
    }).catchError((error) {
      stdout.write('Ошибка при чтении файла: $error');
      exit(0);
    });

    if (directory.existsSync()) {
      final files = directory.listSync();
      for (var file in files) {
        if (file is File && file.uri.pathSegments.last != 'input.txt') {
          final fileName = file.uri.pathSegments.last;
          final name = fileName.replaceAll(RegExp(r'(\.dart|_)'), '');
          final response = await sendRequestToChatGPT(
            'Поменяй везде слово teacher на $name в этом коде сохраняя регистр $templateQuery',
          );
          ++queryCounter;
          if (queryCounter > 2) {
            sleep(Duration(minutes: 1));
            queryCounter = 0;
          }
          createFile(fileName, response);
        }
      }
    } else {
      stdout.write('Директория не существует: $directory');
      exit(0);
    }
  } catch (error) {
    stdout.write('Ошибка обработки запроса. Пожалуйста, ознакомьтесь с README.md этого CLI.');
    exit(0);
  }
}

Future<void> createFile(String fileName, String response) async {
  await Directory('output').create(recursive: true).then((_) {
    final file = File('output/$fileName');
    file.writeAsStringSync(response);
  });
}
