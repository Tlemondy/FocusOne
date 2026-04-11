import 'package:cloud_firestore/cloud_firestore.dart';

class FriendStatsSummary {
  const FriendStatsSummary({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.completedSessions = 0,
    this.ratingCount = 0,
    this.ratingTotal = 0,
  });

  final int totalSessions;
  final int totalMinutes;
  final int completedSessions;
  final int ratingCount;
  final int ratingTotal;

  double get averageRating => ratingCount == 0 ? 0 : ratingTotal / ratingCount;

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'completedSessions': completedSessions,
      'ratingCount': ratingCount,
      'ratingTotal': ratingTotal,
      'averageRating': averageRating,
    };
  }

  factory FriendStatsSummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const FriendStatsSummary();
    }

    return FriendStatsSummary(
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
      completedSessions: (map['completedSessions'] as num?)?.toInt() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      ratingTotal: (map['ratingTotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class PublicUserProfile {
  const PublicUserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.emailLowercase,
    this.photoUrl,
    this.photoDataBase64,
    this.photoMimeType,
    this.stats = const FriendStatsSummary(),
  });

  final String uid;
  final String displayName;
  final String email;
  final String emailLowercase;
  final String? photoUrl;
  final String? photoDataBase64;
  final String? photoMimeType;
  final FriendStatsSummary stats;

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'emailLowercase': emailLowercase,
      'photoUrl': photoUrl,
      'photoDataBase64': photoDataBase64,
      'photoMimeType': photoMimeType,
      'stats': stats.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PublicUserProfile.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return PublicUserProfile(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      emailLowercase: (data['emailLowercase'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoDataBase64: data['photoDataBase64'] as String?,
      photoMimeType: data['photoMimeType'] as String?,
      stats: FriendStatsSummary.fromMap(data['stats'] as Map<String, dynamic>?),
    );
  }
}

class FriendConnection {
  const FriendConnection({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.photoDataBase64,
    this.photoMimeType,
    this.connectedAt,
    this.updatedAt,
    this.stats = const FriendStatsSummary(),
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? photoDataBase64;
  final String? photoMimeType;
  final DateTime? connectedAt;
  final DateTime? updatedAt;
  final FriendStatsSummary stats;

  double get averageRating => stats.averageRating;

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'photoDataBase64': photoDataBase64,
      'photoMimeType': photoMimeType,
      'connectedAt': connectedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(connectedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
      'stats': stats.toMap(),
    };
  }

  factory FriendConnection.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return FriendConnection(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoDataBase64: data['photoDataBase64'] as String?,
      photoMimeType: data['photoMimeType'] as String?,
      connectedAt: (data['connectedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      stats: FriendStatsSummary.fromMap(data['stats'] as Map<String, dynamic>?),
    );
  }

  factory FriendConnection.fromPublicProfile(
    PublicUserProfile profile, {
    DateTime? connectedAt,
  }) {
    return FriendConnection(
      uid: profile.uid,
      displayName: profile.displayName,
      email: profile.email,
      photoUrl: profile.photoUrl,
      photoDataBase64: profile.photoDataBase64,
      photoMimeType: profile.photoMimeType,
      connectedAt: connectedAt,
      stats: profile.stats,
    );
  }
}
