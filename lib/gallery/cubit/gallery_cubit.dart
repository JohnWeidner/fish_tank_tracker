import 'dart:async';
import 'dart:math';

import 'package:fish_tank_tracker/gallery/cubit/gallery_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template gallery_cubit}
/// Manages the state of the gallery feature.
/// {@endtemplate}
class GalleryCubit extends Cubit<GalleryState> {
  /// {@macro gallery_cubit}
  GalleryCubit({
    required TankRepository tankRepository,
  })  : _tankRepository = tankRepository,
        super(const GalleryLoading());

  final TankRepository _tankRepository;
  StreamSubscription<List<TankEntry>>? _subscription;

  /// Starts watching tank entries.
  void load() {
    _subscription?.cancel();
    _subscription = _tankRepository.watchEntries().listen(
      (entries) {
        final livestock = entries
            .where((e) => e.type == TankEntryType.livestock)
            .toList();
        final plants = entries
            .where((e) => e.type == TankEntryType.plant)
            .toList();

        final current = state;
        final showingLivestock = switch (current) {
          GalleryLoaded(:final showingLivestock) => showingLivestock,
          _ => true,
        };
        final currentIndex = switch (current) {
          GalleryLoaded(:final currentIndex) => currentIndex,
          _ => 0,
        };
        final activeList = showingLivestock ? livestock : plants;
        final clampedIndex = activeList.isEmpty
            ? 0
            : min(currentIndex, activeList.length - 1);
        emit(
          GalleryLoaded(
            livestock: livestock,
            plants: plants,
            showingLivestock: showingLivestock,
            currentIndex: clampedIndex,
          ),
        );
      },
      onError: (Object error) {
        emit(GalleryFailure(error.toString()));
      },
    );
  }

  /// Updates the current page index.
  void pageChanged(int index) {
    final current = state;
    if (current is GalleryLoaded) {
      emit(current.copyWith(currentIndex: index));
    }
  }

  /// Toggles between livestock and plants.
  void toggleSection() {
    final current = state;
    if (current is GalleryLoaded) {
      emit(
        current.copyWith(
          showingLivestock: !current.showingLivestock,
          currentIndex: 0,
        ),
      );
    }
  }

  /// Creates a new entry with the given image and returns it.
  Future<TankEntry> addEntry(String imagePath) async {
    final id = await _tankRepository.addEntry(
      type: TankEntryType.livestock,
      imagePath: imagePath,
    );
    return TankEntry(
      id: id,
      type: TankEntryType.livestock,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
