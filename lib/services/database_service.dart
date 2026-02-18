import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'image_storage.dart';

class DatabaseService extends ChangeNotifier {
  static const _kUsers         = 'users_v2';
  static const _kPosts         = 'posts_v2';   // sem imageBase64 — fica no IndexedDB
  static const _kPins          = 'pins_v2';
  static const _kComments      = 'comments_v2';
  static const _kNotifications = 'notifications_v2';
  static const _kFollows       = 'follows_v2';
  static const _kCurrentUser   = 'current_user_v2';

  final _uuid = const Uuid();
  SharedPreferences? _prefs;

  AppUser?              _currentUser;
  List<Post>            _posts         = [];
  List<Pin>             _pins          = [];
  List<PostComment>     _comments      = [];
  List<AppNotification> _notifications = [];
  List<Follow>          _follows       = [];
  List<AppUser>         _users         = [];

  AppUser?              get currentUser       => _currentUser;
  bool                  get isLoggedIn        => _currentUser != null;
  List<Post>            get posts             => _posts;
  List<AppUser>         get users             => _users;
  List<Follow>          get follows           => _follows;
  List<AppNotification> get notifications     => _notifications;

  int get unreadNotifCount => _notifications
      .where((n) => n.recipientId == _currentUser?.id && !n.isRead)
      .length;

  // ── INIT ────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAll();
    if (_users.isEmpty) await _seedDemoData();
    final uid = _prefs!.getString(_kCurrentUser);
    if (uid != null) {
      try { _currentUser = _users.firstWhere((u) => u.id == uid); } catch (_) {}
    }
    // Carregar imagens do IndexedDB para cada post
    await _loadPostImages();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    _users         = _loadList(_kUsers,         (j) => AppUser.fromJson(j));
    _posts         = _loadList(_kPosts,         (j) => Post.fromJson(j));
    _pins          = _loadList(_kPins,          (j) => Pin.fromJson(j));
    _comments      = _loadList(_kComments,      (j) => PostComment.fromJson(j));
    _notifications = _loadList(_kNotifications, (j) => AppNotification.fromJson(j));
    _follows       = _loadList(_kFollows,       (j) => Follow.fromJson(j));
  }

  /// Carrega as imagens do IndexedDB e injeta nos posts correspondentes.
  /// Posts com imageBase64 = 'idb:<id>' buscam a imagem no IndexedDB.
  Future<void> _loadPostImages() async {
    bool changed = false;
    for (final post in _posts) {
      if (post.imageBase64.startsWith('idb:')) {
        final key = post.imageBase64.substring(4); // remove 'idb:'
        final b64 = await ImageStorage.loadBase64(key);
        if (b64 != null && b64.isNotEmpty) {
          post.imageBase64 = b64;
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  List<T> _loadList<T>(String key, T Function(Map<String,dynamic>) fromJson) {
    final raw = _prefs?.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String,dynamic>)).toList();
    } catch (_) { return []; }
  }

  /// Salva metadados no SharedPreferences.
  /// Para posts: substitui imageBase64 pelo ponteiro 'idb:<id>' antes de salvar.
  Future<void> _save(String key, List items) async {
    try {
      List<Map<String, dynamic>> jsonList;
      if (key == _kPosts) {
        // Salva posts sem as imagens grandes — usa referência 'idb:<id>'
        jsonList = (items as List<Post>).map((p) {
          final map = p.toJson();
          // Se a imageBase64 é uma imagem real (não demo e não já é ponteiro)
          if (!map['imageBase64'].toString().startsWith('demo:') &&
              !map['imageBase64'].toString().startsWith('idb:') &&
              map['imageBase64'].toString().length > 100) {
            map['imageBase64'] = 'idb:${p.id}';
          }
          return map;
        }).toList();
      } else if (key == _kUsers) {
        // Salva usuários sem avatars grandes
        jsonList = (items as List<AppUser>).map((u) {
          final map = u.toJson();
          if ((map['avatarBase64'] ?? '').toString().length > 100) {
            map['avatarBase64'] = 'idb:avatar_${u.id}';
          }
          return map;
        }).toList();
      } else {
        jsonList = items.map((e) => e.toJson() as Map<String, dynamic>).toList();
      }
      final json = jsonEncode(jsonList);
      await _prefs?.setString(key, json);
    } catch (e) {
      if (kDebugMode) debugPrint('_save erro [$key]: $e');
    }
  }

  // ── AUTH ────────────────────────────────────────────────────────────────────
  String _hash(String s) => base64Encode(utf8.encode(s));

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return 'E-mail já cadastrado.';
    }
    if (password.length < 6) return 'Senha deve ter pelo menos 6 caracteres.';
    final user = AppUser(
      id: _uuid.v4(), name: name, email: email,
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    await _save(_kUsers, _users);
    _currentUser = user;
    await _prefs?.setString(_kCurrentUser, user.id);
    notifyListeners();
    return null;
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      final user = _users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (user.passwordHash != _hash(password)) return 'Senha incorreta.';
      _currentUser = user;
      await _prefs?.setString(_kCurrentUser, user.id);
      // Carregar avatar do IndexedDB se necessário
      final av = _currentUser!.avatarBase64;
      if (av != null && av.startsWith('idb:')) {
        final key = av.substring(4);
        final b64 = await ImageStorage.loadBase64(key);
        if (b64 != null) _currentUser!.avatarBase64 = b64;
      }
      notifyListeners();
      return null;
    } catch (_) {
      return 'E-mail não encontrado.';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs?.remove(_kCurrentUser);
    notifyListeners();
  }

  // ── USER ────────────────────────────────────────────────────────────────────
  AppUser? getUserById(String id) {
    try { return _users.firstWhere((u) => u.id == id); } catch (_) { return null; }
  }

  List<AppUser> searchUsers(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _users.where((u) =>
        u.id != _currentUser?.id &&
        (u.name.toLowerCase().contains(q) ||
         u.email.toLowerCase().contains(q))).toList();
  }

  Future<void> updateUserProfile({
    String? name,
    String? bio,
    bool? allowPublicPins,
    Uint8List? avatarBytes,
  }) async {
    if (_currentUser == null) return;
    if (name != null)            { _currentUser!.name = name; }
    if (bio != null)             { _currentUser!.bio = bio; }
    if (allowPublicPins != null) { _currentUser!.allowPublicPinsOnMyPosts = allowPublicPins; }
    if (avatarBytes != null) {
      final b64 = base64Encode(avatarBytes);
      _currentUser!.avatarBase64 = b64;
      // Salva avatar no IndexedDB
      await ImageStorage.saveBase64('avatar_${_currentUser!.id}', b64);
    }

    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx != -1) _users[idx] = _currentUser!;
    await _save(_kUsers, _users);

    // Propagar nome/avatar para posts
    if (name != null || avatarBytes != null) {
      for (final p in _posts.where((p) => p.ownerId == _currentUser!.id)) {
        if (name != null) p.ownerName = name;
        if (avatarBytes != null) p.ownerAvatarBase64 = _currentUser!.avatarBase64;
      }
      await _save(_kPosts, _posts);
    }
    notifyListeners();
  }

  // ── FOLLOWS ──────────────────────────────────────────────────────────────────
  bool isFollowing(String targetId) => _follows.any(
      (f) => f.followerId == _currentUser?.id && f.followingId == targetId);

  int followersCount(String userId) =>
      _follows.where((f) => f.followingId == userId).length;

  int followingCount(String userId) =>
      _follows.where((f) => f.followerId == userId).length;

  List<String> followingIds(String userId) =>
      _follows.where((f) => f.followerId == userId).map((f) => f.followingId).toList();

  Future<void> toggleFollow(String targetId) async {
    final myId = _currentUser!.id;
    final existing = _follows.indexWhere(
        (f) => f.followerId == myId && f.followingId == targetId);
    if (existing != -1) {
      _follows.removeAt(existing);
    } else {
      _follows.add(Follow(
          followerId: myId, followingId: targetId, createdAt: DateTime.now()));
      _addNotification(
        recipientId: targetId,
        type: NotifType.newFollower,
        body: '${_currentUser!.name} começou a seguir você.',
      );
    }
    await _save(_kFollows, _follows);
    notifyListeners();
  }

  // ── POSTS ───────────────────────────────────────────────────────────────────
  Future<Post> createPost({
    required Uint8List imageBytes,
    required String caption,
  }) async {
    final pid = _uuid.v4();
    final imgB64 = base64Encode(imageBytes);

    // Salva imagem no IndexedDB (sem limite de tamanho)
    await ImageStorage.saveBase64(pid, imgB64);

    final post = Post(
      id: pid,
      ownerId: _currentUser!.id,
      ownerName: _currentUser!.name,
      ownerAvatarBase64: _currentUser!.avatarBase64,
      imageBase64: imgB64,   // na memória fica o base64 completo
      caption: caption,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);

    // No SharedPreferences salva o ponteiro 'idb:<pid>' (pouco espaço)
    await _save(_kPosts, _posts);
    notifyListeners();
    return post;
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    _pins.removeWhere((p) => p.postId == postId);
    _comments.removeWhere((c) => c.postId == postId);
    await ImageStorage.delete(postId);   // remove imagem do IndexedDB
    await _save(_kPosts, _posts);
    await _save(_kPins, _pins);
    await _save(_kComments, _comments);
    notifyListeners();
  }

  Future<void> updatePostPrivacy(String postId, bool allowPublic) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].allowPublicPinsOverride = allowPublic;
    await _save(_kPosts, _posts);
    notifyListeners();
  }

  List<Post> getAllFeedPosts() {
    final list = List<Post>.from(_posts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> getFeedPosts() {
    final followedIds = followingIds(_currentUser?.id ?? '').toSet();
    final myId = _currentUser?.id ?? '';
    List<Post> list;
    if (followedIds.isEmpty) {
      list = List<Post>.from(_posts);
    } else {
      final relevant = {...followedIds, myId};
      list = _posts.where((p) => relevant.contains(p.ownerId)).toList();
      if (list.isEmpty) list = List<Post>.from(_posts);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> getUserPosts(String userId) {
    final list = _posts.where((p) => p.ownerId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> getRankingPosts({int minPins = 5, int topN = 50}) {
    final list = _posts.where((p) => p.totalPins >= minPins).toList();
    list.sort((a, b) => b.notaMedia.compareTo(a.notaMedia));
    return list.take(topN).toList();
  }

  Post? getPostById(String id) {
    try { return _posts.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }

  // ── PINS ─────────────────────────────────────────────────────────────────────
  List<Pin> getVisiblePins(String postId) {
    final post = getPostById(postId);
    if (post == null) return [];
    final currentUserId = _currentUser?.id;
    final postOwner = getUserById(post.ownerId);
    final ownerAllowsPublic = (postOwner?.allowPublicPinsOnMyPosts ?? true) &&
        post.allowPublicPinsOverride;
    return _pins.where((pin) {
      if (pin.postId != postId || pin.isDeleted) return false;
      if (currentUserId == post.ownerId)  return true;
      if (currentUserId == pin.authorId)  return true;
      if (!ownerAllowsPublic)             return false;
      return pin.isPublic;
    }).toList();
  }

  int getPinCountForUserOnPost(String postId, String userId) =>
      _pins.where((p) => p.postId == postId && p.authorId == userId && !p.isDeleted).length;

  Future<String?> createPin({
    required String postId,
    required double xPercent,
    required double yPercent,
    required String targetLabel,
    required double score,
    required String comment,
    required bool isPublic,
  }) async {
    final uid = _currentUser!.id;
    if (getPinCountForUserOnPost(postId, uid) >= 10) {
      return 'Você já atingiu o limite de 10 pins nesta foto.';
    }
    if (targetLabel.trim().isEmpty) return 'Informe um título/alvo para o pin.';

    final pin = Pin(
      id: _uuid.v4(), postId: postId,
      authorId: uid, authorName: _currentUser!.name,
      authorAvatarBase64: _currentUser!.avatarBase64,
      xPercent: xPercent, yPercent: yPercent,
      targetLabel: targetLabel.trim(),
      score: score.clamp(0.0, 10.0),
      comment: comment, isPublic: isPublic,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    _pins.add(pin);
    await _save(_kPins, _pins);
    await _recalculatePost(postId);

    final post = getPostById(postId);
    if (post != null && post.ownerId != uid) {
      _addNotification(
        recipientId: post.ownerId,
        type: NotifType.newPin,
        body: '${_currentUser!.name} avaliou "${post.caption.isEmpty ? 'sua foto' : post.caption}" com nota ${score.toStringAsFixed(1)} no pin "${targetLabel.trim()}".',
        postId: postId,
      );
    }
    notifyListeners();
    return null;
  }

  Future<String?> editPin({
    required String pinId,
    String? targetLabel, double? score, String? comment, bool? isPublic,
  }) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return 'Pin não encontrado.';
    if (_pins[idx].authorId != _currentUser!.id) return 'Sem permissão.';

    if (targetLabel != null) _pins[idx].targetLabel = targetLabel.trim();
    if (score != null)       _pins[idx].score = score.clamp(0.0, 10.0);
    if (comment != null)     _pins[idx].comment = comment;
    if (isPublic != null)    _pins[idx].isPublic = isPublic;
    _pins[idx].updatedAt = DateTime.now();

    await _save(_kPins, _pins);
    await _recalculatePost(_pins[idx].postId);
    notifyListeners();
    return null;
  }

  Future<void> deletePin(String pinId) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    final postId = _pins[idx].postId;
    _pins[idx].isDeleted = true;
    await _save(_kPins, _pins);
    await _recalculatePost(postId);
    notifyListeners();
  }

  Future<void> _recalculatePost(String postId) async {
    final active = _pins.where((p) => p.postId == postId && !p.isDeleted).toList();
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final total = active.length;
    final media = total > 0
        ? active.map((p) => p.score).reduce((a, b) => a + b) / total : 0.0;
    _posts[idx].notaMedia        = double.parse(media.toStringAsFixed(1));
    _posts[idx].totalPins        = total;
    _posts[idx].totalAvaliadores = active.map((p) => p.authorId).toSet().length;
    await _save(_kPosts, _posts);
  }

  // ── COMMENTS ─────────────────────────────────────────────────────────────────
  List<PostComment> getCommentsForPost(String postId) {
    return _comments
        .where((c) => c.postId == postId && !c.isDeleted)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<String?> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return 'Comentário não pode ser vazio.';
    final comment = PostComment(
      id: _uuid.v4(), postId: postId,
      authorId: _currentUser!.id, authorName: _currentUser!.name,
      authorAvatarBase64: _currentUser!.avatarBase64,
      text: text.trim(), createdAt: DateTime.now(),
    );
    _comments.add(comment);

    final pIdx = _posts.indexWhere((p) => p.id == postId);
    if (pIdx != -1) {
      _posts[pIdx].totalComments =
          _comments.where((c) => c.postId == postId && !c.isDeleted).length;
    }
    await _save(_kComments, _comments);
    await _save(_kPosts, _posts);

    final post = getPostById(postId);
    if (post != null && post.ownerId != _currentUser!.id) {
      _addNotification(
        recipientId: post.ownerId,
        type: NotifType.newComment,
        body: '${_currentUser!.name} comentou: "${text.trim().length > 60 ? '${text.trim().substring(0, 60)}…' : text.trim()}"',
        postId: postId,
      );
    }
    notifyListeners();
    return null;
  }

  Future<void> deleteComment(String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final postId = _comments[idx].postId;
    _comments[idx].isDeleted = true;
    final pIdx = _posts.indexWhere((p) => p.id == postId);
    if (pIdx != -1) {
      _posts[pIdx].totalComments =
          _comments.where((c) => c.postId == postId && !c.isDeleted).length;
    }
    await _save(_kComments, _comments);
    await _save(_kPosts, _posts);
    notifyListeners();
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────────
  List<AppNotification> getMyNotifications() {
    return _notifications
        .where((n) => n.recipientId == _currentUser?.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _addNotification({
    required String recipientId,
    required NotifType type,
    required String body,
    String? postId,
    String? pinId,
  }) {
    final notif = AppNotification(
      id: _uuid.v4(), recipientId: recipientId,
      actorId: _currentUser!.id, actorName: _currentUser!.name,
      actorAvatarBase64: _currentUser!.avatarBase64,
      type: type, postId: postId, pinId: pinId,
      body: body, createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    _save(_kNotifications, _notifications);
  }

  Future<void> markAllNotificationsRead() async {
    for (final n in _notifications) { n.isRead = true; }
    await _save(_kNotifications, _notifications);
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) _notifications[idx].isRead = true;
    await _save(_kNotifications, _notifications);
    notifyListeners();
  }

  // ── DEMO DATA ─────────────────────────────────────────────────────────────────
  Future<void> _seedDemoData() async {
    final u1 = AppUser(id: 'demo-1', name: 'Ana Silva',    email: 'ana@demo.com',     passwordHash: _hash('123456'), createdAt: DateTime.now().subtract(const Duration(days: 30)));
    final u2 = AppUser(id: 'demo-2', name: 'Pedro Costa',  email: 'pedro@demo.com',   passwordHash: _hash('123456'), createdAt: DateTime.now().subtract(const Duration(days: 20)));
    final u3 = AppUser(id: 'demo-3', name: 'Mariana Lima', email: 'mariana@demo.com', passwordHash: _hash('123456'), createdAt: DateTime.now().subtract(const Duration(days: 10)));
    _users = [u1, u2, u3];

    _follows = [
      Follow(followerId: 'demo-1', followingId: 'demo-2', createdAt: DateTime.now()),
      Follow(followerId: 'demo-2', followingId: 'demo-1', createdAt: DateTime.now()),
      Follow(followerId: 'demo-3', followingId: 'demo-1', createdAt: DateTime.now()),
    ];

    // Posts de demo usam imageBase64 com prefixo 'demo:' (renderizados como gradiente)
    final p1 = Post(id: 'post-1', ownerId: 'demo-1', ownerName: 'Ana Silva',
        imageBase64: 'demo:7C3AED:EC4899:1', caption: 'Meu look favorito ✨',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        notaMedia: 8.6, totalPins: 6, totalAvaliadores: 2, totalComments: 2);
    final p2 = Post(id: 'post-2', ownerId: 'demo-2', ownerName: 'Pedro Costa',
        imageBase64: 'demo:10B981:3B82F6:2', caption: 'Treino concluído 💪',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        notaMedia: 7.8, totalPins: 6, totalAvaliadores: 2, totalComments: 1);
    final p3 = Post(id: 'post-3', ownerId: 'demo-3', ownerName: 'Mariana Lima',
        imageBase64: 'demo:F59E0B:EF4444:3', caption: 'Pôr do sol incrível 🌅',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        notaMedia: 9.0, totalPins: 6, totalAvaliadores: 3, totalComments: 3);
    final p4 = Post(id: 'post-4', ownerId: 'demo-1', ownerName: 'Ana Silva',
        imageBase64: 'demo:EC4899:F59E0B:4', caption: 'Novo corte 💇‍♀️',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        notaMedia: 6.0, totalPins: 5, totalAvaliadores: 2, totalComments: 0);
    _posts = [p1, p2, p3, p4];

    _pins = [
      Pin(id: 'pin-1', postId: 'post-1', authorId: 'demo-2', authorName: 'Pedro Costa', xPercent: 30, yPercent: 25, targetLabel: 'Cabelo', score: 9.0, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Pin(id: 'pin-2', postId: 'post-1', authorId: 'demo-2', authorName: 'Pedro Costa', xPercent: 50, yPercent: 50, targetLabel: 'Roupa', score: 8.5, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Pin(id: 'pin-3', postId: 'post-1', authorId: 'demo-3', authorName: 'Mariana Lima', xPercent: 45, yPercent: 30, targetLabel: 'Expressão', score: 9.0, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Pin(id: 'pin-4', postId: 'post-2', authorId: 'demo-1', authorName: 'Ana Silva', xPercent: 50, yPercent: 40, targetLabel: 'Postura', score: 8.0, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Pin(id: 'pin-5', postId: 'post-3', authorId: 'demo-1', authorName: 'Ana Silva', xPercent: 60, yPercent: 30, targetLabel: 'Céu', score: 9.5, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Pin(id: 'pin-6', postId: 'post-3', authorId: 'demo-2', authorName: 'Pedro Costa', xPercent: 40, yPercent: 60, targetLabel: 'Horizonte', score: 9.0, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Pin(id: 'pin-7', postId: 'post-3', authorId: 'demo-3', authorName: 'Mariana Lima', xPercent: 50, yPercent: 50, targetLabel: 'Composição', score: 8.5, isPublic: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ];

    _comments = [
      PostComment(id: 'c-1', postId: 'post-1', authorId: 'demo-2', authorName: 'Pedro Costa', text: 'Ficou incrível! 😍', createdAt: DateTime.now()),
      PostComment(id: 'c-2', postId: 'post-1', authorId: 'demo-3', authorName: 'Mariana Lima', text: 'Arrasou!', createdAt: DateTime.now()),
      PostComment(id: 'c-3', postId: 'post-2', authorId: 'demo-1', authorName: 'Ana Silva', text: 'Top demais! 💪', createdAt: DateTime.now()),
      PostComment(id: 'c-4', postId: 'post-3', authorId: 'demo-1', authorName: 'Ana Silva', text: 'Que foto linda!', createdAt: DateTime.now()),
      PostComment(id: 'c-5', postId: 'post-3', authorId: 'demo-2', authorName: 'Pedro Costa', text: 'Perfeita ✨', createdAt: DateTime.now()),
      PostComment(id: 'c-6', postId: 'post-3', authorId: 'demo-3', authorName: 'Mariana Lima', text: 'Meu pôr do sol favorito!', createdAt: DateTime.now()),
    ];

    await _save(_kUsers, _users);
    await _save(_kPosts, _posts);
    await _save(_kPins, _pins);
    await _save(_kComments, _comments);
    await _save(_kFollows, _follows);
  }
}
