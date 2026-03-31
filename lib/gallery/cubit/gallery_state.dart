import 'package:equatable/equatable.dart';
import 'package:tank_repository/tank_repository.dart';

/// The state of the gallery feature.
sealed class GalleryState {
  const GalleryState();
}

/// The gallery is loading entries.
class GalleryLoading extends GalleryState {
  /// Creates a [GalleryLoading].
  const GalleryLoading();
}

/// The gallery has loaded entries.
class GalleryLoaded extends GalleryState with EquatableMixin {
  /// Creates a [GalleryLoaded].
  const GalleryLoaded({
    required this.livestock,
    required this.plants,
    this.currentIndex = 0,
    this.showingLivestock = true,
  });

  /// All livestock entries.
  final List<TankEntry> livestock;

  /// All plant entries.
  final List<TankEntry> plants;

  /// The current page index in the gallery.
  final int currentIndex;

  /// Whether showing livestock (true) or plants (false).
  final bool showingLivestock;

  /// The currently displayed list.
  List<TankEntry> get currentEntries =>
      showingLivestock ? livestock : plants;

  /// Creates a copy with the given fields replaced.
  GalleryLoaded copyWith({
    List<TankEntry>? livestock,
    List<TankEntry>? plants,
    int? currentIndex,
    bool? showingLivestock,
  }) {
    return GalleryLoaded(
      livestock: livestock ?? this.livestock,
      plants: plants ?? this.plants,
      currentIndex: currentIndex ?? this.currentIndex,
      showingLivestock: showingLivestock ?? this.showingLivestock,
    );
  }

  @override
  List<Object?> get props => [
        livestock,
        plants,
        currentIndex,
        showingLivestock,
      ];
}

/// The gallery failed to load.
class GalleryFailure extends GalleryState {
  /// Creates a [GalleryFailure].
  const GalleryFailure(this.message);

  /// The error message.
  final String message;
}
