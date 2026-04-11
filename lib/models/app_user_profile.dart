import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.photoDataBase64,
    this.photoMimeType,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? photoDataBase64;
  final String? photoMimeType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? photoDataBase64,
    String? photoMimeType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPhotoUrl = false,
    bool clearPhotoData = false,
  }) {
    return AppUserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      photoDataBase64: clearPhotoData
          ? null
          : (photoDataBase64 ?? this.photoDataBase64),
      photoMimeType: clearPhotoData
          ? null
          : (photoMimeType ?? this.photoMimeType),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUserProfile(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoDataBase64: data['photoDataBase64'] as String?,
      photoMimeType: data['photoMimeType'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
