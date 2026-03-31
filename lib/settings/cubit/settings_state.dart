/// Transient message to show after a settings action.
enum SettingsMessage {
  /// The API key was saved. Restart to apply.
  saved,

  /// The API key was removed. Restart to apply.
  removed,
}

/// The state of the settings feature.
sealed class SettingsState {
  const SettingsState();
}

/// Settings are loading.
class SettingsLoading extends SettingsState {
  /// Creates a [SettingsLoading].
  const SettingsLoading();
}

/// Settings have loaded.
class SettingsLoaded extends SettingsState {
  /// Creates a [SettingsLoaded].
  const SettingsLoaded({required this.hasApiKey, this.message});

  /// Whether an API key is currently stored.
  final bool hasApiKey;

  /// Optional transient message for snackbar display.
  final SettingsMessage? message;
}

/// Settings encountered an error.
class SettingsFailure extends SettingsState {
  /// Creates a [SettingsFailure].
  const SettingsFailure(this.message);

  /// The error message.
  final String message;
}
