import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Upload profile picture via backend API
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final response = await _apiService.uploadProfileImage(imageFile);
      
      if (response['success'] == true && response['data'] != null) {
        final avatarUrl = response['data']['avatar'] as String;
        return avatarUrl;
      } else {
        throw Exception(response['message'] ?? 'Failed to upload profile picture');
      }
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
}

