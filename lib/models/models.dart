class AppUser {
  final String id;
  String name;
  String email;
  final String passwordHash;
  String? avatarBase64;
  bool allowPublicPinsOnMyPosts;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarBase64,
    this.allowPublicPinsOnMyPosts = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'avatarBase64': avatarBase64,
        'allowPublicPinsOnMyPosts': allowPublicPinsOnMyPosts,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        avatarBase64: json['avatarBase64'] as String?,
        allowPublicPinsOnMyPosts: json['allowPublicPinsOnMyPosts'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Post {
  final String id;
  final String ownerId;
  String ownerName;
  String? ownerAvatarBase64;
  final String imageBase64;
  String caption;
  final DateTime createdAt;
  double notaMedia;
  int totalPins;
  int totalAvaliadores;
  bool allowPublicPinsOverride;

  Post({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarBase64,
    required this.imageBase64,
    this.caption = '',
    required this.createdAt,
    this.notaMedia = 0.0,
    this.totalPins = 0,
    this.totalAvaliadores = 0,
    this.allowPublicPinsOverride = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerAvatarBase64': ownerAvatarBase64,
        'imageBase64': imageBase64,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
        'notaMedia': notaMedia,
        'totalPins': totalPins,
        'totalAvaliadores': totalAvaliadores,
        'allowPublicPinsOverride': allowPublicPinsOverride,
      };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        ownerName: json['ownerName'] as String,
        ownerAvatarBase64: json['ownerAvatarBase64'] as String?,
        imageBase64: json['imageBase64'] as String,
        caption: json['caption'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        notaMedia: (json['notaMedia'] as num?)?.toDouble() ?? 0.0,
        totalPins: json['totalPins'] as int? ?? 0,
        totalAvaliadores: json['totalAvaliadores'] as int? ?? 0,
        allowPublicPinsOverride: json['allowPublicPinsOverride'] as bool? ?? true,
      );
}

class Pin {
  final String id;
  final String postId;
  final String authorId;
  String authorName;
  String? authorAvatarBase64;
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
    this.authorAvatarBase64,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarBase64': authorAvatarBase64,
        'xPercent': xPercent,
        'yPercent': yPercent,
        'targetLabel': targetLabel,
        'score': score,
        'comment': comment,
        'isPublic': isPublic,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Pin.fromJson(Map<String, dynamic> json) => Pin(
        id: json['id'] as String,
        postId: json['postId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        authorAvatarBase64: json['authorAvatarBase64'] as String?,
        xPercent: (json['xPercent'] as num).toDouble(),
        yPercent: (json['yPercent'] as num).toDouble(),
        targetLabel: json['targetLabel'] as String,
        score: (json['score'] as num).toDouble(),
        comment: json['comment'] as String? ?? '',
        isPublic: json['isPublic'] as bool? ?? true,
        isDeleted: json['isDeleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
