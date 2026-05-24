import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class PlatformImage {
  static ImageProvider fromPath(String path) {
    return FileImage(File(path));
  }

  static ImageProvider fromBytes(Uint8List bytes) {
    return MemoryImage(bytes);
  }

  static Widget image(String? path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (path == null) return const SizedBox.shrink();
    return Image.file(File(path), fit: fit, width: width, height: height);
  }

  static ImageProvider? provider(String? path, {Uint8List? bytes}) {
    if (path != null) return fromPath(path);
    if (bytes != null) return fromBytes(bytes);
    return null;
  }
}
