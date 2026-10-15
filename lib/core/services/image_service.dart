import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service wrapping image selection and camera capture.
class ImageService {
  final ImagePicker _picker;

  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Captures an image using device camera
  Future<String?> captureFromCamera({
    CameraDevice preferredCamera = CameraDevice.rear,
    int imageQuality = 90,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCamera,
        imageQuality: imageQuality,
      );
      return photo?.path;
    } catch (e) {
      debugPrint('Error capturing photo from camera: $e');
      rethrow;
    }
  }

  /// Picks an existing receipt image from device gallery
  Future<String?> pickFromGallery({int imageQuality = 90}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }
}

