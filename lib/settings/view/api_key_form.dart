import 'package:fish_tank_tracker/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// {@template api_key_form}
/// Form for entering and managing the Gemini API key.
/// {@endtemplate}
class ApiKeyForm extends StatefulWidget {
  /// {@macro api_key_form}
  const ApiKeyForm({required this.hasApiKey, super.key});

  /// Whether an API key is currently stored.
  final bool hasApiKey;

  @override
  State<ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends State<ApiKeyForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini API Key',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.hasApiKey
                      ? 'An API key is configured. AI species identification '
                          'is enabled.'
                      : 'No API key configured. Add your Gemini API key '
                          'to enable AI species identification.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (widget.hasApiKey) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('API key configured'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<SettingsCubit>().removeApiKey();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove API Key'),
                  ),
                ] else ...[
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIza...',
                      border: OutlineInputBorder(),
                    ),

                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      final key = _controller.text.trim();
                      if (key.isNotEmpty) {
                        context.read<SettingsCubit>().saveApiKey(key);
                        _controller.clear();
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save API Key'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fish Tank Tracker uses Gemini AI to identify fish and '
                  'plants from photos. The API key is stored securely on '
                  'your device and never shared.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
