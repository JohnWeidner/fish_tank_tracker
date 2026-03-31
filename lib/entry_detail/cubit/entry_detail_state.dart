import 'package:equatable/equatable.dart';
import 'package:tank_repository/tank_repository.dart';

/// The state of the entry detail feature.
sealed class EntryDetailState extends Equatable {
  const EntryDetailState();

  @override
  List<Object?> get props => [];
}

/// The entry detail has loaded.
class EntryDetailLoaded extends EntryDetailState {
  /// Creates an [EntryDetailLoaded].
  const EntryDetailLoaded({
    required this.entry,
    this.isIdentifying = false,
  });

  /// The current entry data.
  final TankEntry entry;

  /// Whether AI identification is in progress.
  final bool isIdentifying;

  @override
  List<Object?> get props => [entry, isIdentifying];
}

/// The entry has been deleted.
class EntryDetailDeleted extends EntryDetailState {
  /// Creates an [EntryDetailDeleted].
  const EntryDetailDeleted();
}
