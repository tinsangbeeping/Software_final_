import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker picker = ImagePicker();

  Future<XFile?> pickImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    return image;
  }
}