import 'package:bloc_test/bloc_test.dart';
import 'package:fish_tank_tracker/settings/cubit/settings_cubit.dart';
import 'package:fish_tank_tracker/settings/cubit/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:secure_storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
  });

  group('SettingsCubit', () {
    blocTest<SettingsCubit, SettingsState>(
      'emits [SettingsLoaded] with hasApiKey true when key exists',
      build: () {
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => true);
        return SettingsCubit(secureStorage: mockSecureStorage);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.hasApiKey, 'hasApiKey', true),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [SettingsLoaded] with hasApiKey false when no key',
      build: () {
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => false);
        return SettingsCubit(secureStorage: mockSecureStorage);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.hasApiKey, 'hasApiKey', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [SettingsLoaded with saved message] when saving key',
      build: () {
        when(() => mockSecureStorage.setApiKey(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => true);
        return SettingsCubit(secureStorage: mockSecureStorage);
      },
      act: (cubit) => cubit.saveApiKey('sk-ant-test-key'),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.hasApiKey, 'hasApiKey', true)
            .having((s) => s.message, 'message', SettingsMessage.saved),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [SettingsLoaded with removed message] when removing key',
      build: () {
        when(() => mockSecureStorage.deleteApiKey())
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.hasApiKey())
            .thenAnswer((_) async => false);
        return SettingsCubit(secureStorage: mockSecureStorage);
      },
      act: (cubit) => cubit.removeApiKey(),
      expect: () => [
        isA<SettingsLoaded>()
            .having((s) => s.hasApiKey, 'hasApiKey', false)
            .having((s) => s.message, 'message', SettingsMessage.removed),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [SettingsFailure] when load throws',
      build: () {
        when(() => mockSecureStorage.hasApiKey())
            .thenThrow(Exception('storage error'));
        return SettingsCubit(secureStorage: mockSecureStorage);
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<SettingsFailure>()],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [SettingsFailure] when saveApiKey throws',
      build: () {
        when(() => mockSecureStorage.setApiKey(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(secureStorage: mockSecureStorage);
      },
      act: (cubit) => cubit.saveApiKey('key'),
      expect: () => [isA<SettingsFailure>()],
    );
  });
}
