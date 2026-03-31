import 'package:flutter/material.dart';

/// The app's theme configuration.
abstract class AppTheme {
  /// The light theme for the app.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      brightness: Brightness.light,
    );
  }
}
