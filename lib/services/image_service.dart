import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/platform_file_ops.dart';

class ImageService {
  final SupabaseClient _supabase;

  ImageService(this._supabase);

  static const String _bucket = 'food-images';

  Future<String?> pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    Uint8List bytes;
    if (kIsWeb) {
      bytes = await image.readAsBytes();
    } else {
      final localBytes = await PlatformFileOps.readImageFile(image.path);
      bytes = localBytes ?? await image.readAsBytes();
    }

    final hash = sha256.convert(bytes).toString();
    final path = '$userId/$hash.jpg';

    await _supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final url = _supabase.storage.from(_bucket).getPublicUrl(path);
    return url;
  }

  Future<ImageProvider> loadImage(String url) async {
    return NetworkImage(url);
  }
}
