import 'package:fish_tank_tracker/settings/cubit/settings_cubit.dart';
import 'package:fish_tank_tracker/settings/cubit/settings_state.dart';
import 'package:fish_tank_tracker/settings/view/api_key_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_storage/secure_storage.dart';

/// {@template settings_page}
/// The settings page that provides the [SettingsCubit].
/// {@endtemplate}
class SettingsPage extends StatelessWidget {
  /// {@macro settings_page}
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(
        secureStorage: context.read<SecureStorage>(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: BlocConsumer<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded && state.message != null) {
              final text = switch (state.message!) {
                SettingsMessage.saved =>
                  'API key saved. Restart the app to apply changes.',
                SettingsMessage.removed =>
                  'API key removed. Restart the app to apply changes.',
              };
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(text)),
              );
            }
          },
          builder: (context, state) {
            return switch (state) {
              SettingsLoading() =>
                const Center(child: CircularProgressIndicator()),
              SettingsFailure(:final message) =>
                Center(child: Text('Error: $message')),
              SettingsLoaded(:final hasApiKey) =>
                ApiKeyForm(hasApiKey: hasApiKey),
            };
          },
        ),
      ),
    );
  }
}
