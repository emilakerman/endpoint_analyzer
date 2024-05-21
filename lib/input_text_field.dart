import 'dart:io';

import 'package:download/download.dart';
import 'package:endpoint_analyzer/gemini_api_handler.dart';
import 'package:endpoint_analyzer/saved_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

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

  Future<void> _download(jsonData) async {
    final DateTime currentTime = DateTime.now();
    final Directory desktopDir = await getDesktopDirectory();
    final String path = desktopDir.path;
    final String file =
        '$path/downloaded_data_${jsonData.hashCode * currentTime.microsecond}.txt';
    final stream = Stream.fromIterable('${await jsonData}'.codeUnits);
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const SavedAlert(),
    );
    await download(stream, file);
  }

  Future<Directory> getDesktopDirectory() async {
    if (Platform.isWindows || Platform.isMacOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  @override
  void initState() {
    jsonData = Future.value('');
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
    final bool validURL = Uri.parse(endpoint).isAbsolute;
    if (!validURL) return;
    final String url = endpoint;
    final Response response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print('Error');
      return [];
    } else {
      print('Success');
      setState(() {
        jsonData = GeminiApiHandler().formatResponse(response.body, endpoint);
      });
      return response.body;
    }
  }

  bool showInfo = false;

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
                    if (_controller.text.isNotEmpty) {
                      if (!_controller.text.contains('http')) return;
                      analyzeEndpoint(_controller.text);
                      setState(() {
                        showInfo = true;
                      });
                    }
                  },
                  child: const Text(
                    'Analyze Endpoint',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        jsonData = Future.value('');
                        _controller.clear();
                        showInfo = false;
                      });
                    }
                  },
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
                                  child: const Text("JSON"),
                                ),
                                ElevatedButton(
                                  onPressed: !isXMLData ? null : () {},
                                  child: const Text("XML"),
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
                    child: showInfo
                        ? FutureBuilder(
                            future: gemini.provideInformationAboutEndpoint(
                                _controller.text),
                            builder: (context, snapshot2) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
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
                                    text: snapshot2.data.toString(),
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink()),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      !_controller.text.isNotEmpty || jsonData != 'Invalid URL'
                          ? null
                          : () {
                              _download(jsonData);
                            },
                  child: const Text("Save data to file"),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: ColoredBox(
                  color: Colors.grey.shade200,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'JSON or XML data will be displayed here...',
                    ),
                    readOnly: true,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller:
                        TextEditingController(text: snapshot.data.toString()),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
