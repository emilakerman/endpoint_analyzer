import 'dart:convert';

import 'package:endpoint_analyzer/gemini_api_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:xml/xml.dart'; // for XML

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const Center(
          child: InputTextField(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Text('Save'),
        ),
      ),
    );
  }
}

class InputTextField extends StatefulWidget {
  const InputTextField({
    super.key,
  });

  @override
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  final TextEditingController _controller = TextEditingController();
  late Future<dynamic> jsonData;
  final GeminiApiHandler gemini = GeminiApiHandler();

  @override
  void initState() {
    jsonData = Future.value([]);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// example https://api.tvmaze.com/singlesearch/shows?q=simpsons
  /// https://api.sr.se/api/v2/scheduledepisodes?channelid=164
  Future<dynamic> analyzeEndpoint(String endpoint) async {
    String url = endpoint;
    final Response response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print('Error');
      return [];
    } else {
      print('Success');
      setState(() {
        jsonData = GeminiApiHandler().formatResponse(response.body);
      });
      return response.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: jsonData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text('Reading and formatting data...'),
              ],
            ),
          );
        }
        return Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Enter an endpoint to analyze:'),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: CupertinoTextField(
                    controller: _controller,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    analyzeEndpoint(_controller.text);
                    gemini.provideInformationAboutEndpoint(_controller.text);
                  },
                  child: const Text(
                    'Analyze Endpoint',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() {
                    jsonData = Future.value([]);
                    _controller.clear();
                  }),
                  child: const Text(
                    'Undo',
                  ),
                ),
                const SizedBox(height: 10),
                _controller.text.isNotEmpty
                    ? FutureBuilder<String>(
                        future: GeminiApiHandler()
                            .xmlOrJson(snapshot.data.toString()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasData) {
                            final bool isJsonData =
                                snapshot.data!.contains('JSON');
                            final bool isXMLData =
                                snapshot.data!.contains('XML');
                            return Row(
                              children: [
                                ElevatedButton(
                                  onPressed: !isJsonData ? null : () {},
                                  child: Text("JSON"),
                                ),
                                ElevatedButton(
                                  onPressed: !isXMLData ? null : () {},
                                  child: Text("XML"),
                                ),
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: FutureBuilder(
                    future: gemini
                        .provideInformationAboutEndpoint(_controller.text),
                    builder: (context, snapshot2) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot2.data == null) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ColoredBox(
                        color: Colors.grey.shade200,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          readOnly: true,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          controller: TextEditingController(
                              text: snapshot2.data.toString() ?? ''),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ColoredBox(
                color: Colors.grey.shade200,
                child: TextField(
                  readOnly: true,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller:
                      TextEditingController(text: snapshot.data.toString()),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
