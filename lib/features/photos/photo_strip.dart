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

/// Saves, once at start, a shot the camera kept when Android stopped the
/// app while it was open, for the record it was taken for.
final lostPhotoRecoveryProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(photoRepositoryProvider);
  final pending = await repo.pendingCapture();
  if (pending == null) return;
  try {
    final jpeg = await ref.read(photoCaptureProvider).recoverLost();
    if (jpeg != null) {
      await repo.add(owner: pending.$1, ownerId: pending.$2, jpeg: jpeg);
    }
  } finally {
    await repo.clearPendingCapture();
  }
});

final photosForProvider =
    StreamProvider.family<List<Photo>, (PhotoOwner, String)>(
      (ref, owner) =>
          ref.watch(photoRepositoryProvider).watchFor(owner.$1, owner.$2),
    );

/// This phone's file for a photo, or null.
/// Downloaded from Storage the first time, when online (plan Decision 11).
/// Dropped when no longer shown, so a photo missing now (offline, not sent
/// yet) is asked for again the next time it is shown.
final photoFileProvider = FutureProvider.autoDispose.family<File?, String>(
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
/// The camera is open for [owner] [ownerId] meanwhile, noted so a shot
/// kept after Android stops the app is saved for it on restart.
Future<Uint8List?> capturePhoto(
  BuildContext context,
  WidgetRef ref,
  PhotoOwner owner,
  String ownerId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).photoFailed;
  final repo = ref.read(photoRepositoryProvider);
  final camera = ref.read(photoCaptureProvider);
  await repo.notePendingCapture(owner, ownerId);
  try {
    return await camera.takeCompressed();
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
    return null;
  } finally {
    await repo.clearPendingCapture();
  }
}

/// The photos of a saved record, with a camera button to add one; a tap on
/// a photo marks it to send or deletes it.
class PhotoStrip extends ConsumerWidget {
  const PhotoStrip({super.key, required this.owner, required this.ownerId});

  final PhotoOwner owner;
  final String ownerId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    // Taken before the camera opens: the screen may be gone when it closes.
    final repo = ref.read(photoRepositoryProvider);
    final jpeg = await capturePhoto(context, ref, owner, ownerId);
    // Saved even if the screen closed meanwhile: the shot is the person's.
    if (jpeg == null) return;
    try {
      await repo.add(owner: owner, ownerId: ownerId, jpeg: jpeg);
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
        // It may be the only copy: ask first.
        if (!context.mounted) return;
        final sure = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.photoDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (sure != true) return;
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
