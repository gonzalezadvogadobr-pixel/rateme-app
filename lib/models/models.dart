import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────
DateTime _toDateTime(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String)    return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

// ── AppUser ───────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  String name;
  String email;
  final String passwordHash;
  String? avatarBase64;   // URL do Firebase Storage ou base64
  bool allowPublicPinsOnMyPosts;
  String bio;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarBase64,
    this.allowPublicPinsOnMyPosts = true,
    this.bio = '',
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> d) => AppUser(
    id: d['id'] as String? ?? '',
    name: d['name'] as String? ?? '',
    email: d['email'] as String? ?? '',
    passwordHash: d['passwordHash'] as String? ?? '',
    avatarBase64: (d['avatarUrl'] ?? d['avatarBase64']) as String?,
    allowPublicPinsOnMyPosts: d['allowPublicPinsOnMyPosts'] as bool? ?? true,
    bio: d['bio'] as String? ?? '',
    createdAt: _toDateTime(d['createdAt']),
  );

  // Para salvar no Firestore (sem imageBase64 enorme, usa avatarUrl)
  Map<String, dynamic> toFirestore() => {
    'name': name, 'email': email,
    'avatarUrl': avatarBase64 ?? '',
    'allowPublicPinsOnMyPosts': allowPublicPinsOnMyPosts,
    'bio': bio,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'passwordHash': passwordHash,
    'avatarBase64': avatarBase64 ?? '',
    'allowPublicPinsOnMyPosts': allowPublicPinsOnMyPosts,
    'bio': bio,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ── Post ──────────────────────────────────────────────────────────────────────
class Post {
  final String id;
  final String ownerId;
  String ownerName;
  String ownerAvatarBase64;   // URL ou base64 do avatar do dono
  String imageBase64;          // URL do Firebase Storage ou base64
  String caption;
  final DateTime createdAt;
  double notaMedia;
  int totalPins;
  int totalAvaliadores;
  int totalComments;
  bool allowPublicPinsOverride;

  Post({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarBase64 = '',
    required this.imageBase64,
    this.caption = '',
    required this.createdAt,
    this.notaMedia = 0.0,
    this.totalPins = 0,
    this.totalAvaliadores = 0,
    this.totalComments = 0,
    this.allowPublicPinsOverride = true,
  });

  factory Post.fromJson(Map<String, dynamic> d) => Post(
    id: d['id'] as String? ?? '',
    ownerId: d['ownerId'] as String? ?? '',
    ownerName: d['ownerName'] as String? ?? '',
    ownerAvatarBase64: (d['ownerAvatarBase64'] ?? d['ownerAvatarUrl'] ?? '') as String,
    imageBase64: (d['imageBase64'] ?? d['imageUrl'] ?? '') as String,
    caption: d['caption'] as String? ?? '',
    createdAt: _toDateTime(d['createdAt']),
    notaMedia: (d['notaMedia'] as num?)?.toDouble() ?? 0.0,
    totalPins: d['totalPins'] as int? ?? 0,
    totalAvaliadores: d['totalAvaliadores'] as int? ?? 0,
    totalComments: d['totalComments'] as int? ?? 0,
    allowPublicPinsOverride: d['allowPublicPinsOverride'] as bool? ?? true,
  );

  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId, 'ownerName': ownerName,
    'ownerAvatarBase64': ownerAvatarBase64,
    'imageBase64': imageBase64,
    'caption': caption,
    'createdAt': Timestamp.fromDate(createdAt),
    'notaMedia': notaMedia, 'totalPins': totalPins,
    'totalAvaliadores': totalAvaliadores, 'totalComments': totalComments,
    'allowPublicPinsOverride': allowPublicPinsOverride,
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'ownerId': ownerId, 'ownerName': ownerName,
    'ownerAvatarBase64': ownerAvatarBase64,
    'imageBase64': imageBase64, 'caption': caption,
    'createdAt': createdAt.toIso8601String(),
    'notaMedia': notaMedia, 'totalPins': totalPins,
    'totalAvaliadores': totalAvaliadores, 'totalComments': totalComments,
    'allowPublicPinsOverride': allowPublicPinsOverride,
  };
}

// ── Pin ───────────────────────────────────────────────────────────────────────
class Pin {
  final String id;
  final String postId;
  final String authorId;
  String authorName;
  String authorAvatarBase64;
  double xPercent;
  double yPercent;
  String targetLabel;
  double score;
  String comment;
  bool isPublic;
  bool isDeleted;
  final DateTime createdAt;
  DateTime updatedAt;

  Pin({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarBase64 = '',
    required this.xPercent,
    required this.yPercent,
    required this.targetLabel,
    required this.score,
    this.comment = '',
    this.isPublic = true,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pin.fromJson(Map<String, dynamic> d) => Pin(
    id: d['id'] as String? ?? '',
    postId: d['postId'] as String? ?? '',
    authorId: d['authorId'] as String? ?? '',
    authorName: d['authorName'] as String? ?? '',
    authorAvatarBase64: d['authorAvatarBase64'] as String? ?? '',
    xPercent: (d['xPercent'] as num?)?.toDouble() ?? 0.0,
    yPercent: (d['yPercent'] as num?)?.toDouble() ?? 0.0,
    targetLabel: d['targetLabel'] as String? ?? '',
    score: (d['score'] as num?)?.toDouble() ?? 0.0,
    comment: d['comment'] as String? ?? '',
    isPublic: d['isPublic'] as bool? ?? true,
    isDeleted: d['isDeleted'] as bool? ?? false,
    createdAt: _toDateTime(d['createdAt']),
    updatedAt: _toDateTime(d['updatedAt']),
  );

  Map<String, dynamic> toFirestore() => {
    'postId': postId, 'authorId': authorId, 'authorName': authorName,
    'authorAvatarBase64': authorAvatarBase64,
    'xPercent': xPercent, 'yPercent': yPercent,
    'targetLabel': targetLabel, 'score': score,
    'comment': comment, 'isPublic': isPublic, 'isDeleted': isDeleted,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'postId': postId, 'authorId': authorId, 'authorName': authorName,
    'authorAvatarBase64': authorAvatarBase64,
    'xPercent': xPercent, 'yPercent': yPercent,
    'targetLabel': targetLabel, 'score': score,
    'comment': comment, 'isPublic': isPublic, 'isDeleted': isDeleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

// ── PostComment ───────────────────────────────────────────────────────────────
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  String authorName;
  String authorAvatarBase64;
  String text;
  bool isDeleted;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarBase64 = '',
    required this.text,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> d) => PostComment(
    id: d['id'] as String? ?? '',
    postId: d['postId'] as String? ?? '',
    authorId: d['authorId'] as String? ?? '',
    authorName: d['authorName'] as String? ?? '',
    authorAvatarBase64: d['authorAvatarBase64'] as String? ?? '',
    text: d['text'] as String? ?? '',
    isDeleted: d['isDeleted'] as bool? ?? false,
    createdAt: _toDateTime(d['createdAt']),
  );

  Map<String, dynamic> toFirestore() => {
    'postId': postId, 'authorId': authorId, 'authorName': authorName,
    'authorAvatarBase64': authorAvatarBase64,
    'text': text, 'isDeleted': isDeleted,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'postId': postId, 'authorId': authorId, 'authorName': authorName,
    'authorAvatarBase64': authorAvatarBase64,
    'text': text, 'isDeleted': isDeleted,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ── AppNotification ───────────────────────────────────────────────────────────
enum NotifType { newPin, newComment, newFollower, pinEdited }

class AppNotification {
  final String id;
  final String recipientId;
  final String actorId;
  String actorName;
  String actorAvatarBase64;
  final NotifType type;
  final String? postId;
  final String? pinId;
  String body;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    this.actorAvatarBase64 = '',
    required this.type,
    this.postId,
    this.pinId,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  IconData get icon {
    switch (type) {
      case NotifType.newPin:      return Icons.push_pin_rounded;
      case NotifType.newComment:  return Icons.comment_rounded;
      case NotifType.newFollower: return Icons.person_add_rounded;
      case NotifType.pinEdited:   return Icons.edit_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotifType.newPin:      return const Color(0xFF7C3AED);
      case NotifType.newComment:  return const Color(0xFF10B981);
      case NotifType.newFollower: return const Color(0xFFEC4899);
      case NotifType.pinEdited:   return const Color(0xFFFFD700);
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> d) => AppNotification(
    id: d['id'] as String? ?? '',
    recipientId: d['recipientId'] as String? ?? '',
    actorId: d['actorId'] as String? ?? '',
    actorName: d['actorName'] as String? ?? '',
    actorAvatarBase64: d['actorAvatarBase64'] as String? ?? '',
    type: NotifType.values.firstWhere(
      (e) => e.name == d['type'],
      orElse: () => NotifType.newPin,
    ),
    postId: d['postId'] as String?,
    pinId: d['pinId'] as String?,
    body: d['body'] as String? ?? '',
    isRead: d['isRead'] as bool? ?? false,
    createdAt: _toDateTime(d['createdAt']),
  );

  Map<String, dynamic> toFirestore() => {
    'recipientId': recipientId, 'actorId': actorId, 'actorName': actorName,
    'actorAvatarBase64': actorAvatarBase64,
    'type': type.name, 'postId': postId, 'pinId': pinId,
    'body': body, 'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Map<String, dynamic> toJson() => {
    'id': id, 'recipientId': recipientId,
    'actorId': actorId, 'actorName': actorName,
    'actorAvatarBase64': actorAvatarBase64,
    'type': type.name, 'postId': postId, 'pinId': pinId,
    'body': body, 'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ── Follow ────────────────────────────────────────────────────────────────────
class Follow {
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory Follow.fromJson(Map<String, dynamic> d) => Follow(
    followerId: d['followerId'] as String? ?? '',
    followingId: d['followingId'] as String? ?? '',
    createdAt: _toDateTime(d['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'followerId': followerId,
    'followingId': followingId,
    'createdAt': createdAt.toIso8601String(),
  };
}
