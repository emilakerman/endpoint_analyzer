import 'package:flutter/material.dart';

class SavedAlert extends StatelessWidget {
  const SavedAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator())),
          Builder(
            builder: (context) {
              Future.delayed(
                const Duration(milliseconds: 800),
                () {
                  Navigator.of(context).pop();
                },
              );
              return const Text('Saving to documents..');
            },
          ),
        ],
      ),
    );
  }
}
