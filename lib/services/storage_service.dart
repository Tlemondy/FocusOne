import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoUploadResult {
  const ProfilePhotoUploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class StorageService {
  StorageService()
    : _storage = FirebaseStorage.instanceFor(bucket: _defaultBucketUri) {
    _logStatic('initialized bucket=$_defaultBucketUri');
  }

  static const String _defaultBucketUri = 'gs://focus-one-dfaf6.appspot.com';
  static const _supportedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  final FirebaseStorage _storage;

  static void _logStatic(String message) {
    debugPrint('PROFILE PHOTO STORAGE: $message');
  }

  void _log(String message) => _logStatic(message);

  Reference _profilePhotoRef(String userId, String extension) {
    return _storage.ref('profile_photos/$userId/avatar.$extension');
  }

  Future<ProfilePhotoUploadResult> uploadProfilePhoto(
    String userId,
    XFile imageFile,
  ) async {
    try {
      _log(
        'upload requested userId=$userId fileName=${imageFile.name} path=${imageFile.path}',
      );
      final imageBytes = await imageFile.readAsBytes();
      final extension = _normalizedExtension(imageFile.name);
      _log(
        'file loaded userId=$userId bytes=${imageBytes.length} extension=$extension',
      );
      final ref = _profilePhotoRef(userId, extension);
      _log('upload target userId=$userId storagePath=${ref.fullPath}');

      final metadata = SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        customMetadata: {'userId': userId},
      );
      _log(
        'upload metadata userId=$userId contentType=${metadata.contentType}',
      );

      final task = ref.putData(imageBytes, metadata);
      task.snapshotEvents.listen(
        (snapshot) {
          _log(
            'upload progress userId=$userId state=${snapshot.state.name} bytes=${snapshot.bytesTransferred}/${snapshot.totalBytes}',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          _log('upload stream error userId=$userId error=$error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );

      final snapshot = await task;
      _log(
        'upload complete userId=$userId state=${snapshot.state.name} bytes=${snapshot.bytesTransferred}/${snapshot.totalBytes}',
      );
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _log('download url resolved userId=$userId url=$downloadUrl');
      await _cleanupObsoleteProfilePhotos(userId, keepExtension: extension);

      return ProfilePhotoUploadResult(
        downloadUrl: downloadUrl,
        storagePath: ref.fullPath,
      );
    } on FirebaseException catch (e, stackTrace) {
      _log(
        'firebase upload error userId=$userId code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _log('upload error userId=$userId error=$e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteProfilePhoto(String userId) async {
    _log('delete requested userId=$userId');

    for (final extension in _supportedExtensions) {
      try {
        final ref = _profilePhotoRef(userId, extension);
        _log('delete attempt userId=$userId storagePath=${ref.fullPath}');
        await ref.delete().timeout(const Duration(seconds: 4));
        _log('delete success userId=$userId storagePath=${ref.fullPath}');
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          _log(
            'delete skipped userId=$userId extension=$extension reason=object-not-found',
          );
          continue;
        }
        _log(
          'delete firebase error userId=$userId extension=$extension code=${e.code} message=${e.message}',
        );
        rethrow;
      } on TimeoutException {
        _log('delete timeout userId=$userId extension=$extension');
        rethrow;
      }
    }
    _log('delete completed userId=$userId');
  }

  Future<void> _cleanupObsoleteProfilePhotos(
    String userId, {
    required String keepExtension,
  }) async {
    _log(
      'cleanup obsolete files start userId=$userId keepExtension=$keepExtension',
    );
    for (final extension in _supportedExtensions) {
      if (extension == keepExtension) continue;

      try {
        final ref = _profilePhotoRef(userId, extension);
        _log(
          'cleanup delete attempt userId=$userId storagePath=${ref.fullPath}',
        );
        await ref.delete().timeout(const Duration(seconds: 2));
        _log(
          'cleanup delete success userId=$userId storagePath=${ref.fullPath}',
        );
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          _log(
            'cleanup delete skipped userId=$userId extension=$extension reason=object-not-found',
          );
          continue;
        }
        _log(
          'cleanup delete firebase error userId=$userId extension=$extension code=${e.code} message=${e.message}',
        );
      } on TimeoutException {
        _log('cleanup delete timeout userId=$userId extension=$extension');
      } catch (e, stackTrace) {
        _log(
          'cleanup delete error userId=$userId extension=$extension error=$e',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    _log('cleanup obsolete files end userId=$userId');
  }

  String _normalizedExtension(String fileName) {
    final segments = fileName.split('.');
    if (segments.length < 2) return 'jpg';

    final extension = segments.last.toLowerCase();
    switch (extension) {
      case 'jpeg':
      case 'jpg':
        return 'jpg';
      case 'png':
      case 'webp':
      case 'gif':
        return extension;
      default:
        return 'jpg';
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
