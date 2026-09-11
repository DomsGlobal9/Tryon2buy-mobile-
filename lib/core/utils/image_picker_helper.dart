import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Phones shoot 12–48 MP. The pipeline works at well under 2K, so the
  /// picker downsizes on the way in: uploads go from ~8 MB to under 1 MB,
  /// which is the difference between a try-on that starts in a second on
  /// mobile data and one that times out.
  static const double maxDimension = 2048;

  /// The server caps uploads at 10 MB; the website checks the same.
  static const int maxBytes = 10 * 1024 * 1024;

  static Future<File?> pickFromGallery({int imageQuality = 90}) =>
      _pick(ImageSource.gallery, imageQuality);

  static Future<File?> captureFromCamera({int imageQuality = 90}) =>
      _pick(ImageSource.camera, imageQuality);

  static Future<File?> _pick(ImageSource source, int imageQuality) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
      );
      if (picked == null) return null;

      final file = File(picked.path);
      if (await file.length() > maxBytes) return null;
      return file;
    } catch (_) {
      // Permission denied, picker dismissed by the OS, or an unreadable
      // file: the caller treats null as "nothing chosen".
      return null;
    }
  }
}
