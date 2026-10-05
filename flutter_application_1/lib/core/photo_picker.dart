import 'package:image_picker/image_picker.dart';

class PickedPhoto {
  const PickedPhoto({required this.path, required this.filename});

  final String path;
  final String filename;
}

abstract class PhotoPicker {
  Future<PickedPhoto?> pick();

  Future<PickedPhoto?> pickFromCamera();
}

class DevicePhotoPicker implements PhotoPicker {
  const DevicePhotoPicker();

  @override
  Future<PickedPhoto?> pick() => _take(ImageSource.gallery);

  @override
  Future<PickedPhoto?> pickFromCamera() => _take(ImageSource.camera);

  Future<PickedPhoto?> _take(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return null;
      return PickedPhoto(path: file.path, filename: file.name);
    } catch (_) {
      return null;
    }
  }
}
