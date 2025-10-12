import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

void main() => runApp(const CodeApp());

class CodeApp extends StatelessWidget {
  const CodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CodeEditorPage(),
    );
  }
}

class CodeEditorPage extends StatefulWidget {
  const CodeEditorPage({super.key});

  @override
  State<CodeEditorPage> createState() => _CodeEditorPageState();
}

class _CodeEditorPageState extends State<CodeEditorPage> {
  final controller = CodeController(
    text: '''
void main() {
  print("Hello Flutter!");
}
''',
    language: dart,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double fontSize = size.width < 600 ? 14 : 18; // 📱 mobile vs 💻 desktop

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Code Editor'),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black87,
          ),
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: CodeField(
              controller: controller,
              textStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize,
                height: 1.3,
                color: Colors.white,
              ),
              expands: true,
              minLines: null,
              maxLines: null,
              lineNumberStyle: LineNumberStyle(
                textStyle: TextStyle(
                  fontSize: fontSize * 0.9,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}