import 'package:endpoint_analyzer/input_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'dotEnv.dev');
  WidgetsFlutterBinding.ensureInitialized();
  Gemini.init(apiKey: dotenv.env['apiKey']!);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: InputTextField(),
        ),
      ),
    );
  }
}
