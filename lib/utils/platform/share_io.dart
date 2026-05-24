import 'package:share_plus/share_plus.dart';

class PlatformShare {
  static Future<void> shareFile(String filePath, String text) async {
    await Share.shareXFiles([XFile(filePath)], subject: text);
  }

  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  static String get exportBasePath => '';
}
