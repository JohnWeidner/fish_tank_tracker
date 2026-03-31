import 'package:fish_tank_tracker/water_log/cubit/water_log_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// {@template add_water_entry_view}
/// Form for adding a new water parameter reading.
/// {@endtemplate}
class AddWaterEntryView extends StatefulWidget {
  /// {@macro add_water_entry_view}
  const AddWaterEntryView({super.key});

  @override
  State<AddWaterEntryView> createState() => _AddWaterEntryViewState();
}

class _AddWaterEntryViewState extends State<AddWaterEntryView> {
  final _phController = TextEditingController();
  final _ammoniaController = TextEditingController();
  final _nitriteController = TextEditingController();
  final _nitrateController = TextEditingController();
  final _tempController = TextEditingController();
  final _ghController = TextEditingController();
  final _khController = TextEditingController();

  @override
  void dispose() {
    _phController.dispose();
    _ammoniaController.dispose();
    _nitriteController.dispose();
    _nitrateController.dispose();
    _tempController.dispose();
    _ghController.dispose();
    _khController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool _hasAnyValue() {
    return [
      _phController,
      _ammoniaController,
      _nitriteController,
      _nitrateController,
      _tempController,
      _ghController,
      _khController,
    ].any((c) => c.text.trim().isNotEmpty);
  }

  void _save() {
    if (!_hasAnyValue()) return;
    context.read<WaterLogCubit>().addReading(
          ph: _parse(_phController),
          ammonia: _parse(_ammoniaController),
          nitrite: _parse(_nitriteController),
          nitrate: _parse(_nitrateController),
          temperature: _parse(_tempController),
          gh: _parse(_ghController),
          kh: _parse(_khController),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Reading',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ParamField(
                  controller: _phController,
                  label: 'pH',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ParamField(
                  controller: _tempController,
                  label: 'Temp (°F)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ParamField(
                  controller: _ammoniaController,
                  label: 'Ammonia',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ParamField(
                  controller: _nitriteController,
                  label: 'Nitrite',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ParamField(
                  controller: _nitrateController,
                  label: 'Nitrate',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ParamField(
                  controller: _ghController,
                  label: 'GH (dGH)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ParamField(
                  controller: _khController,
                  label: 'KH (dKH)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Reading'),
          ),
        ],
      ),
    );
  }
}

class _ParamField extends StatelessWidget {
  const _ParamField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
    );
  }
}
