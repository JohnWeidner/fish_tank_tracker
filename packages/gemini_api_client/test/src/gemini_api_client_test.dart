import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gemini_api_client/gemini_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;
  late GeminiApiClient client;

  const apiKey = 'test-api-key';
  const imagePath = 'test/fixtures/test_image.jpg';

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    client = GeminiApiClient(
      apiKey: apiKey,
      httpClient: mockHttpClient,
    );
  });

  String geminiSuccessResponse({
    String commonName = 'Neon Tetra',
    String scientificName = 'Paracheirodon innesi',
    String type = 'livestock',
  }) {
    return jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'text': jsonEncode({
                  'commonName': commonName,
                  'scientificName': scientificName,
                  'type': type,
                }),
              },
            ],
          },
        },
      ],
    });
  }

  group('GeminiApiClient', () {
    test('returns IdentificationResult on successful identification', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(geminiSuccessResponse(), 200),
      );

      final result = await client.identify(imagePath);

      expect(result.commonName, equals('Neon Tetra'));
      expect(result.scientificName, equals('Paracheirodon innesi'));
      expect(result.type, equals('livestock'));
    });

    test('sends correct endpoint with API key and model', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(geminiSuccessResponse(), 200),
      );

      await client.identify(imagePath);

      final captured = verify(
        () => mockHttpClient.post(
          captureAny(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;

      final uri = captured[0] as Uri;
      expect(uri.toString(), contains('gemini-2.5-flash:generateContent'));
      expect(uri.toString(), contains('key=test-api-key'));
    });

    test('throws InvalidApiKeyFailure on 401', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Unauthorized', 401),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<InvalidApiKeyFailure>()),
      );
    });

    test('throws InvalidApiKeyFailure on 403', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Forbidden', 403),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<InvalidApiKeyFailure>()),
      );
    });

    test('throws RateLimitedFailure on 429', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Rate limited', 429),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test('throws TimeoutFailure on timeout', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => throw TimeoutException('timed out'),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<TimeoutFailure>()),
      );
    });

    test('throws NetworkFailure on SocketException', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => throw const SocketException('no internet'),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('throws ParseFailure on malformed response', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('not json', 200),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('throws ParseFailure on unexpected status code', () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('server error', 500),
      );

      expect(
        () => client.identify(imagePath),
        throwsA(isA<ParseFailure>()),
      );
    });
  });
}
