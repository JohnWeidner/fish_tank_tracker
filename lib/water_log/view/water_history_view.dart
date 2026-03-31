import 'package:fish_tank_tracker/water_log/cubit/water_log_cubit.dart';
import 'package:fish_tank_tracker/water_log/cubit/water_log_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_repository/water_repository.dart';

/// {@template water_history_view}
/// Displays the history of water parameter readings.
/// {@endtemplate}
class WaterHistoryView extends StatelessWidget {
  /// {@macro water_history_view}
  const WaterHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterLogCubit, WaterLogState>(
      builder: (context, state) {
        return switch (state) {
          WaterLogLoading() =>
            const Center(child: CircularProgressIndicator()),
          WaterLogFailure(:final message) =>
            Center(child: Text('Error: $message')),
          WaterLogLoaded(:final readings) => readings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop_outlined, size: 64),
                      SizedBox(height: 16),
                      Text('No readings yet'),
                      SizedBox(height: 8),
                      Text('Tap + to log your first water test'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    return _ReadingCard(reading: readings[index]);
                  },
                ),
        };
      },
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading});

  final WaterParameters reading;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(reading.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      onDismissed: (_) {
        context.read<WaterLogCubit>().deleteReading(reading.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(reading.recordedAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (reading.ph != null)
                    _ParamChip(
                      label: 'pH',
                      value: reading.ph!,
                      isWarning: reading.isPhWarning,
                    ),
                  if (reading.ammonia != null)
                    _ParamChip(
                      label: 'NH3',
                      value: reading.ammonia!,
                      isWarning: reading.isAmmoniaWarning,
                    ),
                  if (reading.nitrite != null)
                    _ParamChip(
                      label: 'NO2',
                      value: reading.nitrite!,
                      isWarning: reading.isNitriteWarning,
                    ),
                  if (reading.nitrate != null)
                    _ParamChip(
                      label: 'NO3',
                      value: reading.nitrate!,
                      isWarning: reading.isNitrateWarning,
                    ),
                  if (reading.temperature != null)
                    _ParamChip(
                      label: '°F',
                      value: reading.temperature!,
                      isWarning: reading.isTemperatureWarning,
                    ),
                  if (reading.gh != null)
                    _ParamChip(
                      label: 'GH',
                      value: reading.gh!,
                      isWarning: reading.isGhWarning,
                    ),
                  if (reading.kh != null)
                    _ParamChip(
                      label: 'KH',
                      value: reading.kh!,
                      isWarning: reading.isKhWarning,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ParamChip extends StatelessWidget {
  const _ParamChip({
    required this.label,
    required this.value,
    required this.isWarning,
  });

  final String label;
  final double value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Chip(
      label: Text(
        '$label: ${value.toStringAsFixed(1)}',
        style: TextStyle(color: color, fontSize: 12),
      ),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
