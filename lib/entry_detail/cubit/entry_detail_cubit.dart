import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template entry_detail_cubit}
/// Manages the state of the entry detail page.
/// {@endtemplate}
class EntryDetailCubit extends Cubit<EntryDetailState> {
  /// {@macro entry_detail_cubit}
  EntryDetailCubit({
    required TankEntry entry,
    required TankRepository tankRepository,
    SpeciesIdentificationRepository? speciesIdentificationRepository,
    this.isNewEntry = false,
  })  : _tankRepository = tankRepository,
        _speciesIdRepo = speciesIdentificationRepository,
        _originalEntry = entry,
        _currentName = entry.name,
        _currentScientificName = entry.scientificName,
        _currentType = entry.type,
        _entry = entry,
        super(EntryDetailLoaded(entry: entry));

  final TankRepository _tankRepository;
  final SpeciesIdentificationRepository? _speciesIdRepo;
  final TankEntry _originalEntry;
  /// The current entry, updated after each save.
  /// May differ from [_originalEntry] after edits.
  TankEntry _entry;

  /// Whether this is a newly created entry (show Cancel instead of Revert).
  final bool isNewEntry;

  /// Tracks the in-flight name before the debounced save completes.
  /// This may differ from [state] during the debounce window.
  String _currentName;

  /// Tracks the in-flight scientific name before the debounced save completes.
  String? _currentScientificName;

  /// Tracks the in-flight type before the save completes.
  /// Updated immediately on [updateType], then persisted via [_save].
  TankEntryType _currentType;
  Timer? _debounceTimer;

  /// Image paths from retakes that are no longer needed.
  /// Cleaned up on [close] or populated on [revert].
  final _orphanedImages = <String>[];

  /// Whether AI identification is available.
  bool get hasAi => _speciesIdRepo != null;

  /// Updates the name with debounced auto-save.
  void updateName(String name) {
    _currentName = name;
    _restartDebounce();
  }

  /// Updates the scientific name with debounced auto-save.
  void updateScientificName(String scientificName) {
    _currentScientificName = scientificName.isEmpty ? null : scientificName;
    _restartDebounce();
  }

  void _restartDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      _save,
    );
  }

  /// Updates the type and saves immediately.
  Future<void> updateType(TankEntryType type) async {
    _debounceTimer?.cancel();
    _currentType = type;
    await _save();
  }

  /// Replaces the entry's image and saves immediately.
  Future<void> updateImage(String imagePath) async {
    _debounceTimer?.cancel();
    // Track the old image for cleanup if it's not the original.
    if (_entry.imagePath != _originalEntry.imagePath) {
      _orphanedImages.add(_entry.imagePath);
    }
    try {
      await _tankRepository.updateEntry(
        id: _entry.id,
        name: _currentName.trim(),
        scientificName: _currentScientificName,
        type: _currentType,
        imagePath: imagePath,
      );
      _entry = _entry.copyWith(imagePath: imagePath);
      emit(EntryDetailLoaded(entry: _entry));
    } on Exception catch (e, st) {
      log('Failed to update image: $e', stackTrace: st);
    }
  }

  /// Cancels the new entry — deletes it from the DB and cleans up images.
  Future<void> cancel() async {
    _debounceTimer?.cancel();
    await _tankRepository.deleteEntry(_entry.id);
    // Clean up the current image file.
    try {
      final file = File(_entry.imagePath);
      if (file.existsSync()) await file.delete();
    } on Exception catch (_) {
      // Best-effort cleanup.
    }
    // Also clean up any orphaned images from retakes.
    _cleanupOrphanedImages();
    emit(const EntryDetailDeleted());
  }

  /// Reverts all changes back to the original entry state.
  Future<void> revert() async {
    _debounceTimer?.cancel();

    // If the current image differs from the original, orphan it.
    if (_entry.imagePath != _originalEntry.imagePath) {
      _orphanedImages.add(_entry.imagePath);
    }

    _currentName = _originalEntry.name;
    _currentScientificName = _originalEntry.scientificName;
    _currentType = _originalEntry.type;
    _entry = _originalEntry;

    try {
      await _tankRepository.updateEntry(
        id: _originalEntry.id,
        name: _originalEntry.name,
        scientificName: _originalEntry.scientificName,
        type: _originalEntry.type,
        imagePath: _originalEntry.imagePath,
      );
      emit(EntryDetailLoaded(entry: _originalEntry));
    } on Exception catch (e, st) {
      log('Failed to revert entry: $e', stackTrace: st);
    }
  }

  /// Deletes the entry.
  Future<void> deleteEntry() async {
    _debounceTimer?.cancel();
    await _tankRepository.deleteEntry(_entry.id);
    emit(const EntryDetailDeleted());
  }

  /// Re-identifies the entry using AI species identification.
  Future<void> reidentify() async {
    if (_speciesIdRepo == null) return;
    final current = state;
    if (current is! EntryDetailLoaded) return;
    if (current.isIdentifying) return;

    emit(EntryDetailLoaded(entry: _entry, isIdentifying: true));

    try {
      final result = await _speciesIdRepo.identify(_entry.imagePath);
      final identifiedType = TankEntryType.values.byName(result.type);
      _currentName = result.commonName;
      _currentScientificName = result.scientificName;
      _currentType = identifiedType;
      _entry = _entry.copyWith(
        name: result.commonName,
        scientificName: Optional(result.scientificName),
        type: identifiedType,
      );
      await _tankRepository.updateEntry(
        id: _entry.id,
        name: result.commonName,
        scientificName: result.scientificName,
        type: identifiedType,
      );
      emit(EntryDetailLoaded(entry: _entry));
    } on IdentificationFailure catch (e) {
      emit(EntryDetailLoaded(entry: _entry));
      log('Identification failed: ${e.message}');
    } on FileSystemException {
      emit(EntryDetailLoaded(entry: _entry));
      log('Photo not found for identification');
    }
  }

  Future<void> _save() async {
    try {
      await _tankRepository.updateEntry(
        id: _entry.id,
        name: _currentName.trim(),
        scientificName: _currentScientificName,
        type: _currentType,
      );
      _entry = _entry.copyWith(
        name: _currentName.trim(),
        scientificName: Optional(_currentScientificName),
        type: _currentType,
      );
      emit(EntryDetailLoaded(entry: _entry));
    } on Exception catch (e, st) {
      log('Failed to save entry: $e', stackTrace: st);
    }
  }

  void _cleanupOrphanedImages() {
    for (final path in _orphanedImages) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } on Exception catch (_) {
        // Best-effort cleanup.
      }
    }
    _orphanedImages.clear();
  }

  @override
  Future<void> close() async {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
      try {
        await _tankRepository.updateEntry(
          id: _entry.id,
          name: _currentName.trim(),
          scientificName: _currentScientificName,
          type: _currentType,
        );
      } on Exception catch (e, st) {
        log('Failed to flush save on close: $e', stackTrace: st);
      }
    }
    _cleanupOrphanedImages();
    return super.close();
  }
}
