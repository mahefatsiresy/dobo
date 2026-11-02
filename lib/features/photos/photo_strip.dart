import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/providers.dart';
import 'photo_capture.dart';

final photosForProvider =
    StreamProvider.family<List<Photo>, (PhotoOwner, String)>(
      (ref, owner) =>
          ref.watch(photoRepositoryProvider).watchFor(owner.$1, owner.$2),
    );

/// This phone's file for a photo, or null.
/// Downloaded from Storage the first time, when online (plan Decision 11).
final photoFileProvider = FutureProvider.family<File?, String>(
  (ref, key) => ref
      .watch(photoFilesProvider)
      .fetch(
        key,
        associationId: ref.watch(sessionProvider).requireValue!.associationId,
        store: ref.watch(photoStoreProvider),
      ),
);

/// Takes a photo; null when cancelled or when it failed, after telling the
/// person the record saves without it (plan Decision 10).
Future<Uint8List?> capturePhoto(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).photoFailed;
  try {
    return await ref.read(photoCaptureProvider).takeCompressed();
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
    return null;
  }
}

/// The photos of a saved record, with a camera button to add one; a tap on
/// a photo marks it to send or deletes it.
class PhotoStrip extends ConsumerWidget {
  const PhotoStrip({super.key, required this.owner, required this.ownerId});

  final PhotoOwner owner;
  final String ownerId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final jpeg = await capturePhoto(context, ref);
    if (jpeg == null) return;
    try {
      await ref
          .read(photoRepositoryProvider)
          .add(owner: owner, ownerId: ownerId, jpeg: jpeg);
    } on FileSystemException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).photoFailed)),
        );
      }
    }
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Photo p) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(photoRepositoryProvider);
    // Only the phone that took it holds the file to send.
    final mine = p.deviceId == ref.read(sessionProvider).value?.deviceId;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mine)
              CheckboxListTile(
                minTileHeight: 56,
                secondary: const Icon(Icons.cloud_upload),
                title: Text(l10n.photoUpload),
                value: p.upload,
                onChanged: (_) => Navigator.pop(context, 'upload'),
              ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.delete),
              title: Text(l10n.photoDelete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'upload':
        await repo.setUpload(p.photoKey, !p.upload);
      case 'delete':
        await repo.delete(p.photoKey);
        ref.invalidate(photoFileProvider(p.photoKey));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photosForProvider((owner, ownerId))).value ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final p in photos)
          InkWell(
            key: ValueKey('photo-${p.photoKey}'),
            onTap: () => _open(context, ref, p),
            child: Stack(
              children: [
                PhotoThumb(photoKey: p.photoKey),
                if (p.upload)
                  const Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(Icons.cloud_upload, size: 18),
                  ),
              ],
            ),
          ),
        AddPhotoButton(onPressed: () => _add(context, ref)),
      ],
    );
  }
}

/// Photos taken for a record not saved yet; the form saves them with it.
class PendingPhotoStrip extends ConsumerWidget {
  const PendingPhotoStrip({super.key, required this.photos});

  final ValueNotifier<List<Uint8List>> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ValueListenableBuilder<List<Uint8List>>(
        valueListenable: photos,
        builder: (context, list, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (i, bytes) in list.indexed)
              InkWell(
                onTap: () => photos.value = [...list]..removeAt(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    cacheWidth: 144,
                  ),
                ),
              ),
            AddPhotoButton(
              onPressed: () async {
                final jpeg = await capturePhoto(context, ref);
                if (jpeg != null) photos.value = [...photos.value, jpeg];
              },
            ),
          ],
        ),
      );
}

class AddPhotoButton extends StatelessWidget {
  const AddPhotoButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
    onPressed: onPressed,
    icon: const Icon(Icons.photo_camera),
    label: Text(AppLocalizations.of(context).photoAdd),
  );
}

/// A photo's thumbnail, or a placeholder when its file isn't on this phone.
class PhotoThumb extends ConsumerWidget {
  const PhotoThumb({super.key, required this.photoKey, this.size = 72});

  final String photoKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(photoFileProvider(photoKey)).value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: file == null
          ? Tooltip(
              message: AppLocalizations.of(context).photoUnavailable,
              child: Container(
                width: size,
                height: size,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported),
              ),
            )
          : Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 2).round(),
            ),
    );
  }
}
