import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

void main() {
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

class InputTextField extends StatefulWidget {
  const InputTextField({
    super.key,
  });

  @override
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  final TextEditingController _controller = TextEditingController();
  dynamic jsonData = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// example https://api.tvmaze.com/shows
  ///
  Future<dynamic> analyzeEndpoint(String endpoint) async {
    String url = endpoint;
    final Response response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print('Error');
      return [];
    } else {
      print('Success');
      setState(() {
        jsonData = response.body;
      });
      return response.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: CupertinoTextField(
                controller: _controller,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => analyzeEndpoint(_controller.text),
              child: const Text(
                'Analyze Endpoint',
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                jsonData = [];
              }),
              child: const Text(
                'Undo',
              ),
            ),
          ],
        ),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            controller: TextEditingController(text: jsonData.toString()),
          ),
        )
      ],
    );
  }
}
