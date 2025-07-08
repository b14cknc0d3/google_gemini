import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:google_gemini/src/config/constants.dart';
import 'package:google_gemini/src/models/config/gemini_safety_settings.dart';
import 'package:google_gemini/src/models/config/gemini_config.dart';
import 'package:google_gemini/src/models/gemini/gemini_reponse.dart';
import 'package:http/http.dart' as http;

const finalPrompt = """

Convert a directory tree into a complete JSON structure.
The output must be a JSON array of objects, each with the following fields:

* path: full relative path from the root
* type: "file" or "directory"
* content:

  * For text/code files (e.g. .dart, .json, .txt, .md), include the file content as a properly escaped string
  * For binary files (e.g. images, videos, executables), **omit this field entirely**
* children: (for directories only) list of nested child objects

The final output must be complete and valid JSON.
Always include project root.

""";

const prefixPrompt = """
You are a software architect tasked with designing a software architecture based on the given prompt.  
Provide a detailed directory tree output including file paths and the full content of each files.
don't include any other instuructions.
always include project root.

""";

/// Convert safetySettings List int a json
List<Map<String, dynamic>> _convertSafetySettings(
    List<SafetySettings> safetySettings) {
  List<Map<String, dynamic>> list = [];
  for (var element in safetySettings) {
    list.add(element.toJson());
  }
  return list;
}

/// Generate Text from a query with Gemini Api and http
/// requires a query, an apiKey,
Future<GeminiHttpResponse> apiGenerateText(
    {required String query,
    required String apiKey,
    required GenerationConfig? config,
    required List<SafetySettings>? safetySettings,
    required bool isFinalGenerate,
    String model = 'gemini-2.5-flash'}) async {
  var url = Uri.https(Constants.endpoit, 'v1beta/models/$model:generateContent',
      {'key': apiKey});

  log("--- Generating ---");

  var response = await http.post(url,
      body: json.encode({
        "contents": [
          {
            "parts": [
              {
                "text": isFinalGenerate ? finalPrompt : prefixPrompt,
              },
              {"text": query}
            ]
          }
        ],
        "safetySettings": _convertSafetySettings(safetySettings ?? []),
        "generationConfig": config?.toJson()
      }),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.userAgentHeader: 'qs_ai_engine/1.0',
      });

  log("--- Http Status ${response.statusCode} ---");

  if (response.statusCode == 200) {
    return GeminiHttpResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception(
        'Failed to Generate Text: ${response.statusCode}\n${response.body}');
  }
}

/// Get streaming response
Stream<String> apiStreamGenerateText(
    {required String query,
    required String apiKey,
    required GenerationConfig? config,
    required List<SafetySettings>? safetySettings,
    required bool isFinalGenerate,
    String model = 'gemini-2.5-flash'}) async* {
  final client = http.Client();

  final request = http.Request(
    'POST',
    Uri.https(Constants.endpoit, 'v1beta/models/$model:generateContent',
        {'key': apiKey}),
  )
    ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
    ..headers[HttpHeaders.userAgentHeader] = 'qs_ai_engine/1.0'
    ..body = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text": isFinalGenerate ? finalPrompt : prefixPrompt,
            },
            {"text": query}
          ]
        }
      ],
      "safetySettings": _convertSafetySettings(safetySettings ?? []),
      "generationConfig": config?.toJson(),
    });
  final response = await client.send(request);
  log("---- response : ${response.statusCode} ----");
  if (response.statusCode == 200) {
    final stream = response.stream.transform(utf8.decoder);

    await for (var chunk in stream) {
      chunk = chunk.trim();
      if (chunk.isEmpty) continue;

      try {
        yield chunk;
      } catch (e) {
        log(e.toString());
      }
    }
  } else {
    final body = await response.stream.bytesToString();
    throw Exception('Failed to Generate Text: ${response.statusCode}\n$body');
  }
}

/// Convert a File into a base64 String
String _convertIntoBase64(File file) {
  log("--- ${file.path} ---");
  List<int> imageBytes = file.readAsBytesSync();
  String base64File = base64Encode(imageBytes);
  return base64File;
}

/// Generate Text from a query with Gemini pro-vision model
/// requires an image File, and a query
Future<GeminiHttpResponse> apiGenerateTextAndImages(
    {required String query,
    required String apiKey,
    required File image,
    required GenerationConfig? config,
    required List<SafetySettings>? safetySettings,
    String model = 'gemini-pro-vision'}) async {
  var url = Uri.https(Constants.endpoit, 'v1beta/models/$model:generateContent',
      {'key': apiKey});

  log("--- Generating From Text and Image ---");

  var base64Imge = _convertIntoBase64(image);

  var response = await http.post(
    url,
    body: json.encode(
      {
        "contents": [
          {
            "parts": [
              {"text": query},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Imge,
                }
              },
            ]
          }
        ],
        "safetySettings": _convertSafetySettings(safetySettings ?? []),
        "generationConfig": config?.toJson(),
      },
    ),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
    },
  );

  log("--- Http Status ${response.statusCode} ---");

  if (response.statusCode == 200) {
    return GeminiHttpResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception(
        'Failed to Generate Text: ${response.statusCode}\n${response.body}');
  }
}
