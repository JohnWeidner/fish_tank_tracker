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
          appBar: AppBar(
            actions: [
              if (state.isIdentifying)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (cubit.hasAi)
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: cubit.reidentify,
                ),
              if (cubit.isNewEntry)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _showCancelConfirmation(context, cubit),
                )
              else
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: () => _showRevertConfirmation(context, cubit),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context, entry),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                flex: 3,
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
                            child: Icon(Icons.broken_image, size: 64),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filled(
                            onPressed: () =>
                                _cropImage(context, cubit, entry),
                            icon: const Icon(Icons.crop),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () => _retakePhoto(context, cubit),
                            icon: const Icon(Icons.camera_alt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
              ),
            ],
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
