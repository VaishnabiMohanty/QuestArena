import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<Result<File>> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress image
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        return Success(File(image.path));
      }
      return const Failure(UnknownError("No image selected"));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  /// Upload profile picture to Firebase Storage
  Future<Result<String>> uploadProfilePicture(String uid, File file) async {
    try {
      final ref = _storage.ref().child('avatars').child('$uid.jpg');
      
      // Upload file
      await ref.putFile(file);
      
      // Get download URL
      final url = await ref.getDownloadURL();
      return Success(url);
    } catch (e) {
      return Failure(DatabaseError("Upload failed: $e"));
    }
  }
}
