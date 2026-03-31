import 'package:fish_tank_tracker/water_log/cubit/water_log_cubit.dart';
import 'package:fish_tank_tracker/water_log/view/add_water_entry_view.dart';
import 'package:fish_tank_tracker/water_log/view/water_history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_repository/water_repository.dart';

/// {@template water_log_page}
/// The water log page that provides the [WaterLogCubit].
/// {@endtemplate}
class WaterLogPage extends StatelessWidget {
  /// {@macro water_log_page}
  const WaterLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WaterLogCubit(
        waterRepository: context.read<WaterRepository>(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Water Parameters')),
        body: const WaterHistoryView(),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () => _showAddDialog(context),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<WaterLogCubit>(),
        child: const AddWaterEntryView(),
      ),
    );
  }
}
