import 'dart:io';

import 'package:fish_tank_tracker/camera/view/camera_page.dart';
import 'package:fish_tank_tracker/gallery/cubit/gallery_cubit.dart';
import 'package:fish_tank_tracker/gallery/cubit/gallery_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template gallery_view}
/// The gallery view displaying full-screen swipeable photos.
/// {@endtemplate}
class GalleryView extends StatelessWidget {
  /// {@macro gallery_view}
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryCubit, GalleryState>(
      builder: (context, state) {
        return switch (state) {
          GalleryLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          GalleryFailure(:final message) => Scaffold(
              body: Center(child: Text('Error: $message')),
            ),
          GalleryLoaded() => _GalleryContent(state: state),
        };
      },
    );
  }
}

class _GalleryContent extends StatelessWidget {
  const _GalleryContent({required this.state});

  final GalleryLoaded state;

  @override
  Widget build(BuildContext context) {
    final entries = state.currentEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tank'),
        actions: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                icon: SvgPicture.asset(
                  'assets/icons/fish.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                label: const Text('Livestock'),
              ),
              const ButtonSegment(
                value: false,
                icon: Icon(Icons.local_florist),
                label: Text('Plants'),
              ),
            ],
            selected: {state.showingLivestock},
            onSelectionChanged: (selected) {
              context.read<GalleryCubit>().toggleSection();
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.showingLivestock)
                    SvgPicture.asset(
                      'assets/icons/fish.svg',
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.outline,
                        BlendMode.srcIn,
                      ),
                    )
                  else
                    Icon(
                      Icons.local_florist,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    state.showingLivestock
                        ? 'No livestock yet'
                        : 'No plants yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first entry'),
                ],
              ),
            )
          : PageView.builder(
              itemCount: entries.length,
              onPageChanged: (index) {
                context.read<GalleryCubit>().pageChanged(index);
              },
              itemBuilder: (context, index) {
                return _EntryCard(entry: entries[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEntry(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addEntry(BuildContext context) async {
    // Uses Navigator.push instead of go_router because the camera
    // returns a result via pop(), like a picker.
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CameraPage(),
      ),
    );
    if (imagePath == null || !context.mounted) return;

    final entry =
        await context.read<GalleryCubit>().addEntry(imagePath);

    if (context.mounted) {
      await context.push(
        '/gallery/${entry.id}?new=true',
        extra: entry,
      );
    }
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final TankEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/gallery/${entry.id}', extra: entry),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'entry-${entry.id}',
            child: Image.file(
              File(entry.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 64),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.hasName ? entry.name : 'Unnamed',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: entry.hasName
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontStyle: entry.hasName
                              ? null
                              : FontStyle.italic,
                        ),
                  ),
                  if (entry.scientificName != null)
                    Text(
                      entry.scientificName!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
