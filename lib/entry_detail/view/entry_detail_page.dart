import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_cubit.dart';
import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_state.dart';
import 'package:fish_tank_tracker/entry_detail/view/entry_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template entry_detail_page}
/// Page that provides the [EntryDetailCubit] and listens for deletion.
/// {@endtemplate}
class EntryDetailPage extends StatelessWidget {
  /// {@macro entry_detail_page}
  const EntryDetailPage({
    required this.entry,
    this.isNewEntry = false,
    super.key,
  });

  /// The entry to display.
  final TankEntry entry;

  /// Whether this is a newly created entry.
  final bool isNewEntry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EntryDetailCubit(
        entry: entry,
        tankRepository: context.read<TankRepository>(),
        speciesIdentificationRepository:
            context.read<SpeciesIdentificationRepository?>(),
        isNewEntry: isNewEntry,
      ),
      child: BlocListener<EntryDetailCubit, EntryDetailState>(
        listener: (context, state) {
          if (state is EntryDetailDeleted) {
            context.pop();
          }
        },
        child: EntryDetailView(initialEntry: entry),
      ),
    );
  }
}
