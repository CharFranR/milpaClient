import 'package:image_picker/image_picker.dart';

class PickedPhoto {
  const PickedPhoto({required this.path, required this.filename});

  final String path;
  final String filename;
}

abstract class PhotoPicker {
  Future<PickedPhoto?> pick();
}

class DevicePhotoPicker implements PhotoPicker {
  const DevicePhotoPicker();

  @override
  Future<PickedPhoto?> pick() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
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
