import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:species_identification_repository/species_identification_repository.dart';

/// {@template gemini_api_client}
/// HTTP client for the Google Gemini Vision API.
///
/// Sends images to the generateContent endpoint for species identification.
/// {@endtemplate}
class GeminiApiClient extends SpeciesIdentificationRepository {
  /// {@macro gemini_api_client}
  GeminiApiClient({
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client();

  final String _apiKey;
  final http.Client _httpClient;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _model = 'gemini-2.5-flash';
  static const _timeout = Duration(seconds: 30);

  static const _systemPrompt = '''
You are an expert aquarist. Identify the fish, plant, or invertebrate in this photo.
Return ONLY a JSON object with these fields:
- "commonName": common English name
- "scientificName": binomial Latin name (or null if unsure)
- "type": "livestock" or "plant"''';

  @override
  Future<IdentificationResult> identify(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': _systemPrompt},
                ],
              },
              'contents': [
                {
                  'parts': [
                    {
                      'inline_data': {
                        'mime_type': 'image/jpeg',
                        'data': base64Image,
                      },
                    },
                    {'text': 'Identify this aquarium species.'},
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'responseSchema': {
                  'type': 'object',
                  'properties': {
                    'commonName': {'type': 'string'},
                    'scientificName': {'type': 'string'},
                    'type': {
                      'type': 'string',
                      'enum': ['livestock', 'plant'],
                    },
                  },
                  'required': ['commonName', 'scientificName', 'type'],
                },
              },
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const TimeoutFailure();
    } on SocketException {
      throw const NetworkFailure();
    }

    switch (response.statusCode) {
      case 200:
        return _parseResponse(response.body);
      case 401 || 403:
        throw const InvalidApiKeyFailure();
      case 429:
        throw const RateLimitedFailure();
      default:
        log('Gemini API error ${response.statusCode}: ${response.body}');
        throw const ParseFailure();
    }
  }

  IdentificationResult _parseResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>;
      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      var text = (parts.first as Map<String, dynamic>)['text'] as String;

      // Strip markdown code fences if present.
      text = text.trim();
      if (text.startsWith('```')) {
        text = text.replaceFirst(RegExp(r'^```\w*\n?'), '');
        text = text.replaceFirst(RegExp(r'\n?```$'), '');
        text = text.trim();
      }

      final resultJson = jsonDecode(text) as Map<String, dynamic>;

      return IdentificationResult(
        commonName: resultJson['commonName'] as String? ?? 'Unknown',
        scientificName: resultJson['scientificName'] as String?,
        type: resultJson['type'] as String? ?? 'livestock',
      );
    } catch (e) {
      if (e is IdentificationFailure) rethrow;
      log('Failed to parse Gemini response: $e\nBody: $body');
      throw const ParseFailure();
    }
  }
}
