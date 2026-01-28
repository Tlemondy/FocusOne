import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      debugPrint('STORAGE SERVICE: Starting upload for user: $userId');
      final ref = _storage.ref('profile_photos/$userId.jpg');
      debugPrint('STORAGE SERVICE: Uploading file...');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );
      
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      debugPrint('STORAGE SERVICE: Upload complete, getting URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('STORAGE SERVICE: Profile photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('STORAGE SERVICE: Upload error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return a placeholder if storage isn't configured
      if (e.toString().contains('object-not-found') || e.toString().contains('storage')) {
        debugPrint('STORAGE SERVICE: Firebase Storage not configured, using placeholder');
        return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userId)}&size=512&background=random';
      }
      rethrow;
    }
  }
}
