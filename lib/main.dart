import 'package:fish_tank_tracker/app/app.dart';
import 'package:flutter/material.dart';
import 'package:gemini_api_client/gemini_api_client.dart';
import 'package:secure_storage/secure_storage.dart';
import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:tank_local_storage/tank_local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final tankRepository = LocalTankRepository(database: database);
  final waterRepository = LocalWaterRepository(database: database);
  const secureStorage = SecureStorage();

  // Clean up any legacy Anthropic key, then load the Gemini key.
  await secureStorage.cleanupLegacyKey();
  final apiKey = await secureStorage.getApiKey();
  SpeciesIdentificationRepository? speciesIdRepo;
  if (apiKey != null && apiKey.isNotEmpty) {
    speciesIdRepo = GeminiApiClient(apiKey: apiKey);
  }

  runApp(
    App(
      tankRepository: tankRepository,
      waterRepository: waterRepository,
      secureStorage: secureStorage,
      speciesIdentificationRepository: speciesIdRepo,
    ),
  );
}
