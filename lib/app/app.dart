import 'package:fish_tank_tracker/app/router.dart';
import 'package:fish_tank_tracker/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_storage/secure_storage.dart';
import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:tank_repository/tank_repository.dart';
import 'package:water_repository/water_repository.dart';

/// {@template app}
/// The root widget of the Fish Tank Tracker app.
/// {@endtemplate}
class App extends StatefulWidget {
  /// {@macro app}
  const App({
    required this.tankRepository,
    required this.waterRepository,
    required this.secureStorage,
    this.speciesIdentificationRepository,
    super.key,
  });

  /// The tank entry repository.
  final TankRepository tankRepository;

  /// The water parameter repository.
  final WaterRepository waterRepository;

  /// Secure storage for API key.
  final SecureStorage secureStorage;

  /// Optional species identification repository (requires API key).
  final SpeciesIdentificationRepository? speciesIdentificationRepository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TankRepository>.value(
          value: widget.tankRepository,
        ),
        RepositoryProvider<WaterRepository>.value(
          value: widget.waterRepository,
        ),
        RepositoryProvider<SecureStorage>.value(
          value: widget.secureStorage,
        ),
        if (widget.speciesIdentificationRepository != null)
          RepositoryProvider<SpeciesIdentificationRepository>.value(
            value: widget.speciesIdentificationRepository!,
          ),
      ],
      child: MaterialApp.router(
        title: 'Fish Tank Tracker',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
