import 'package:fish_tank_tracker/settings/cubit/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_storage/secure_storage.dart';

/// {@template settings_cubit}
/// Manages the state of the settings feature (API key management).
/// {@endtemplate}
class SettingsCubit extends Cubit<SettingsState> {
  /// {@macro settings_cubit}
  SettingsCubit({required SecureStorage secureStorage})
      : _secureStorage = secureStorage,
        super(const SettingsLoading());

  final SecureStorage _secureStorage;

  /// Loads the current settings state.
  Future<void> load() async {
    try {
      final hasKey = await _secureStorage.hasApiKey();
      emit(SettingsLoaded(hasApiKey: hasKey));
    } on Exception catch (e) {
      emit(SettingsFailure(e.toString()));
    }
  }

  /// Saves an API key.
  Future<void> saveApiKey(String key) async {
    try {
      await _secureStorage.setApiKey(key);
      final hasKey = await _secureStorage.hasApiKey();
      emit(SettingsLoaded(hasApiKey: hasKey, message: SettingsMessage.saved));
    } on Exception catch (e) {
      emit(SettingsFailure(e.toString()));
    }
  }

  /// Removes the stored API key.
  Future<void> removeApiKey() async {
    try {
      await _secureStorage.deleteApiKey();
      final hasKey = await _secureStorage.hasApiKey();
      emit(
        SettingsLoaded(hasApiKey: hasKey, message: SettingsMessage.removed),
      );
    } on Exception catch (e) {
      emit(SettingsFailure(e.toString()));
    }
  }
}
