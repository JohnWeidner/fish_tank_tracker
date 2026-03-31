import 'dart:io';

import 'package:fish_tank_tracker/camera/view/camera_page.dart';
import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_cubit.dart';
import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template entry_detail_view}
/// View for the entry detail page with inline editing.
/// {@endtemplate}
class EntryDetailView extends StatefulWidget {
  /// {@macro entry_detail_view}
  const EntryDetailView({required this.initialEntry, super.key});

  /// The initial entry used to populate the text controller.
  final TankEntry initialEntry;

  @override
  State<EntryDetailView> createState() => _EntryDetailViewState();
}

class _EntryDetailViewState extends State<EntryDetailView> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialEntry.name);
  late final TextEditingController _scientificNameController =
      TextEditingController(text: widget.initialEntry.scientificName ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EntryDetailCubit, EntryDetailState>(
      listener: (context, state) {
        if (state is! EntryDetailLoaded) return;
        // Sync text controllers when AI identification or revert updates
        // the entry.
        if (state.entry.name != _nameController.text) {
          _nameController.text = state.entry.name;
        }
        final scientificName = state.entry.scientificName ?? '';
        if (scientificName != _scientificNameController.text) {
          _scientificNameController.text = scientificName;
        }
      },
      builder: (context, state) {
        if (state is! EntryDetailLoaded) return const SizedBox.shrink();

        final entry = state.entry;
        final cubit = context.read<EntryDetailCubit>();

        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.45,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'entry-${entry.id}',
                        child: Image.file(
                          File(entry.imagePath),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child:
                                  Icon(Icons.broken_image, size: 64),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _cropImage(context, cubit, entry),
                                  icon: const Icon(Icons.crop),
                                  tooltip: 'Crop',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _retakePhoto(context, cubit),
                                  icon: const Icon(Icons.camera_alt),
                                  tooltip: 'Retake',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI identification button — placed near the fields
                      // it fills in.
                      if (cubit.hasAi)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: state.isIdentifying
                              ? const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Identifying...'),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: ActionChip(
                                    avatar:
                                        const Icon(Icons.auto_awesome),
                                    label:
                                        const Text('Identify with AI'),
                                    onPressed: cubit.reidentify,
                                  ),
                                ),
                        ),
                      TextField(
                        controller: _nameController,
                        onChanged: cubit.updateName,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: UnderlineInputBorder(),
                        ),
                        style:
                            Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _scientificNameController,
                        onChanged: cubit.updateScientificName,
                        decoration: const InputDecoration(
                          labelText: 'Scientific name',
                          border: UnderlineInputBorder(),
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<TankEntryType>(
                        segments: [
                          ButtonSegment(
                            value: TankEntryType.livestock,
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
                            value: TankEntryType.plant,
                            icon: Icon(Icons.local_florist),
                            label: Text('Plant'),
                          ),
                        ],
                        selected: {entry.type},
                        onSelectionChanged: (selected) {
                          cubit.updateType(selected.first);
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Added ${DateFormat.yMMMd().format(entry.createdAt)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      // Action buttons at the bottom.
                      if (cubit.isNewEntry)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                _showCancelConfirmation(context, cubit),
                            child: const Text('Discard Entry'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                _showRevertConfirmation(context, cubit),
                            child: const Text('Revert Changes'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () =>
                              _showDeleteConfirmation(context, entry),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                          ),
                          child: const Text('Delete Entry'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cropImage(
    BuildContext context,
    EntryDetailCubit cubit,
    TankEntry entry,
  ) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: entry.imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Photo'),
      ],
    );
    if (croppedFile != null) {
      await cubit.updateImage(croppedFile.path);
    }
  }

  Future<void> _retakePhoto(
    BuildContext context,
    EntryDetailCubit cubit,
  ) async {
    // Uses Navigator.push instead of go_router because the camera
    // returns a result via pop(), like a picker.
    final newPath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CameraPage(),
      ),
    );
    if (newPath != null) {
      await cubit.updateImage(newPath);
    }
  }

  void _showCancelConfirmation(
    BuildContext context,
    EntryDetailCubit cubit,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard entry?'),
        content: const Text(
          'This will delete the photo and entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.cancel();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showRevertConfirmation(
    BuildContext context,
    EntryDetailCubit cubit,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revert changes?'),
        content: const Text(
          'Undo all changes and restore the original entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.revert();
            },
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TankEntry entry) {
    final cubit = context.read<EntryDetailCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          entry.hasName
              ? 'Remove ${entry.name} from your tank?'
              : 'Remove this entry from your tank?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.deleteEntry();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
