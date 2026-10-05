import 'package:flutter_application_1/core/photo_picker.dart';

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.result});

  final PickedPhoto? result;
  int calls = 0;
  int cameraCalls = 0;

  @override
  Future<PickedPhoto?> pick() async {
    calls++;
    return result;
  }

  @override
  Future<PickedPhoto?> pickFromCamera() async {
    cameraCalls++;
    return result;
  }
}
