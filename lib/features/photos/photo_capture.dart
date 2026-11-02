import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Takes a photo with the camera, compressed (SPEC §8); null when the
/// person cancels.
abstract interface class PhotoCapture {
  Future<Uint8List?> takeCompressed();
}

/// The camera, then JPEG at quality 70 with the long edge at 1280 px, and
/// once more at 50 when that is still over 250 KB (SPEC §8).
class CameraPhotoCapture implements PhotoCapture {
  static const longEdgePx = 1280;
  static const quality = 70;
  static const retryQuality = 50;
  static const targetBytes = 250 * 1024;

  @override
  Future<Uint8List?> takeCompressed() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: longEdgePx.toDouble(),
      maxHeight: longEdgePx.toDouble(),
    );
    if (shot == null) return null;
    final raw = await shot.readAsBytes();
    Future<Uint8List> compress(int q) => FlutterImageCompress.compressWithList(
      raw,
      minWidth: longEdgePx,
      minHeight: longEdgePx,
      quality: q,
    );
    final first = await compress(quality);
    return first.length <= targetBytes ? first : compress(retryQuality);
  }
}

final photoCaptureProvider = Provider<PhotoCapture>(
  (ref) => CameraPhotoCapture(),
);
