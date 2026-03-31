import 'package:fish_tank_tracker/gallery/cubit/gallery_cubit.dart';
import 'package:fish_tank_tracker/gallery/view/gallery_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template gallery_page}
/// The gallery page that provides the [GalleryCubit].
/// {@endtemplate}
class GalleryPage extends StatelessWidget {
  /// {@macro gallery_page}
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GalleryCubit(
        tankRepository: context.read<TankRepository>(),
      )..load(),
      child: const GalleryView(),
    );
  }
}
