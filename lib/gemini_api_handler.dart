import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:logger/logger.dart';

class GeminiApiHandler {
  final Gemini gemini = Gemini.instance;

  Future<String> provideInformationAboutEndpoint(String endpoint) async {
    final bool validURL = Uri.parse(endpoint).isAbsolute;
    try {
      if (endpoint.isEmpty) return '';
      if (!validURL) return '';
      final response = await gemini.text(
          "Tell me what api this is and give me some basic information about the API $endpoint.");
      if (response != null) {
        return '${response.output}';
      } else {
        return "No output received from the Gemini API.";
      }
    } catch (e) {
      if (e is GeminiException) {
        return "GeminiException: ${e.message}";
      } else {
        return "An unexpected error occurred: $e";
      }
    }
  }

  Future<String> formatResponse(String unFormattedData, String endpoint) async {
    try {
      Logger().d('Trying to format...');
      final response = await gemini.text(
          "Format this json or xml code to be more readable $unFormattedData.");

      if (response != null && response.output != null) {
        await provideInformationAboutEndpoint(endpoint);
        return '${response.output}';
      } else {
        Logger().d('No output received from the Gemini API');
        return "No output received from the Gemini API.";
      }
    } catch (e) {
      Logger().d('Format failed!');

      if (e is GeminiException) {
        Logger().e("Status Code: ${e.statusCode}");
        Logger().e("Response Data: ${e.message}");
        return "Invalid URL";
      } else {
        Logger().e("Unexpected error: $e");
        return "Invalid URL";
      }
    }
  }

  Future<String> xmlOrJson(String unFormattedData) async {
    if (unFormattedData.isEmpty) {
      return "";
    }
    try {
      Logger().d('Trying to figure out data type...');
      final response = await gemini.text(
          "Is this data in xml or json format? Only accepted answers are XML or JSON: $unFormattedData.");

      if (response != null && response.output != null) {
        return '${response.output}';
      } else {
        Logger().d('No output received from the Gemini API');
        return "No output received from the Gemini API.";
      }
    } catch (e) {
      Logger().d('Format failed!');

      if (e is GeminiException) {
        Logger().e("Status Code: ${e.statusCode}");
        Logger().e("Response Data: ${e.message}");
        return "GeminiException: ${e.message}";
      } else {
        Logger().e("Unexpected error: $e");
        return "An unexpected error occurred: $e";
      }
    }
  }
}
