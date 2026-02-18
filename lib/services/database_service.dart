import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DatabaseService extends ChangeNotifier {
  final _auth    = FirebaseAuth.instance;
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid    = const Uuid();

  AppUser?              _currentUser;
  List<Post>            _posts         = [];
  List<Pin>             _pins          = [];
  List<PostComment>     _comments      = [];
  List<AppNotification> _notifications = [];
  List<Follow>          _follows       = [];
  List<AppUser>         _users         = [];
  bool                  _isLoading     = true;

  // Stream subscriptions para atualizações em tempo real
  Stream<List<Post>>? _postsStream;

  AppUser?              get currentUser       => _currentUser;
  bool                  get isLoggedIn        => _currentUser != null;
  bool                  get isLoading         => _isLoading;
  List<Post>            get posts             => _posts;
  List<AppUser>         get users             => _users;
  List<Follow>          get follows           => _follows;
  List<AppNotification> get notifications     => _notifications;
  int get unreadNotifCount => _notifications
      .where((n) => n.recipientId == _currentUser?.id && !n.isRead)
      .length;

  // ── INIT ────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadCurrentUser(firebaseUser.uid);
        await _loadAllData();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DB] init erro: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCurrentUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromJson({...doc.data()!, 'id': doc.id});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DB] _loadCurrentUser erro: $e');
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUsers(),
      _loadPosts(),
      _loadPins(),
      _loadComments(),
      _loadFollows(),
      _loadNotifications(),
    ]);
  }

  Future<void> _loadUsers() async {
    try {
      final snap = await _db.collection('users').get();
      _users = snap.docs.map((d) => AppUser.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) { if (kDebugMode) debugPrint('[DB] _loadUsers: $e'); }
  }

  Future<void> _loadPosts() async {
    try {
      final snap = await _db.collection('posts').orderBy('createdAt', descending: true).get();
      _posts = snap.docs.map((d) => Post.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) { if (kDebugMode) debugPrint('[DB] _loadPosts: $e'); }
  }

  Future<void> _loadPins() async {
    try {
      final snap = await _db.collection('pins').get();
      _pins = snap.docs.map((d) => Pin.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) { if (kDebugMode) debugPrint('[DB] _loadPins: $e'); }
  }

  Future<void> _loadComments() async {
    try {
      final snap = await _db.collection('comments').get();
      _comments = snap.docs.map((d) => PostComment.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) { if (kDebugMode) debugPrint('[DB] _loadComments: $e'); }
  }

  Future<void> _loadFollows() async {
    try {
      final snap = await _db.collection('follows').get();
      _follows = snap.docs.map((d) => Follow.fromJson(d.data())).toList();
    } catch (e) { if (kDebugMode) debugPrint('[DB] _loadFollows: $e'); }
  }

  Future<void> _loadNotifications() async {
    if (_currentUser == null) return;
    try {
      final snap = await _db.collection('notifications')
          .where('recipientId', isEqualTo: _currentUser!.id)
          .get();
      _notifications = snap.docs
          .map((d) => AppNotification.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) { if (kDebugMode) debugPrint('[DB] _loadNotifications: $e'); }
  }

  // ── AUTH ────────────────────────────────────────────────────────────────────
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final uid = cred.user!.uid;
      final user = AppUser(
        id: uid, name: name, email: email,
        passwordHash: '', createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(uid).set(user.toFirestore());
      _currentUser = user;
      _users.add(user);
      await _loadAllData();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Erro ao criar conta: $e';
    }
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      await _loadCurrentUser(cred.user!.uid);
      await _loadAllData();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Erro ao fazer login: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _posts = []; _pins = []; _comments = [];
    _notifications = []; _follows = []; _users = [];
    notifyListeners();
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'E-mail já cadastrado.';
      case 'invalid-email':        return 'E-mail inválido.';
      case 'weak-password':        return 'Senha muito fraca (mínimo 6 caracteres).';
      case 'user-not-found':       return 'E-mail não encontrado.';
      case 'wrong-password':       return 'Senha incorreta.';
      case 'invalid-credential':   return 'E-mail ou senha incorretos.';
      case 'too-many-requests':    return 'Muitas tentativas. Tente mais tarde.';
      default:                     return 'Erro de autenticação ($code).';
    }
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
    final updates = <String, dynamic>{};
    if (name != null)            { _currentUser!.name = name;   updates['name'] = name; }
    if (bio != null)             { _currentUser!.bio = bio;     updates['bio'] = bio; }
    if (allowPublicPins != null) {
      _currentUser!.allowPublicPinsOnMyPosts = allowPublicPins;
      updates['allowPublicPinsOnMyPosts'] = allowPublicPins;
    }
    if (avatarBytes != null) {
      final url = await _uploadImage(
        'avatars/${_currentUser!.id}.jpg', avatarBytes,
      );
      if (url != null) {
        _currentUser!.avatarBase64 = url;
        updates['avatarUrl'] = url;
      }
    }
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(_currentUser!.id).update(updates);
    }
    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx != -1) _users[idx] = _currentUser!;

    if (name != null || avatarBytes != null) {
      final batch = _db.batch();
      for (final p in _posts.where((p) => p.ownerId == _currentUser!.id)) {
        if (name != null) p.ownerName = name;
        if (avatarBytes != null) p.ownerAvatarBase64 = _currentUser!.avatarBase64 ?? '';
        batch.update(_db.collection('posts').doc(p.id), {
          if (name != null) 'ownerName': name,
          if (avatarBytes != null) 'ownerAvatarBase64': _currentUser!.avatarBase64,
        });
      }
      await batch.commit();
    }
    notifyListeners();
  }

  // ── UPLOAD IMAGEM (Firebase Storage) ─────────────────────────────────────────
  Future<String?> _uploadImage(String path, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      // Usar getDownloadURL() para obter URL real com token de acesso
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('[DB] _uploadImage erro: $e');
      // Fallback: salvar como base64 se Storage falhar
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
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
    final docId = '${myId}_$targetId';
    final existing = _follows.indexWhere(
        (f) => f.followerId == myId && f.followingId == targetId);
    if (existing != -1) {
      _follows.removeAt(existing);
      await _db.collection('follows').doc(docId).delete();
    } else {
      final follow = Follow(followerId: myId, followingId: targetId, createdAt: DateTime.now());
      _follows.add(follow);
      await _db.collection('follows').doc(docId).set(follow.toJson());
      _addNotification(
        recipientId: targetId,
        type: NotifType.newFollower,
        body: '${_currentUser!.name} começou a seguir você.',
      );
    }
    notifyListeners();
  }

  // ── POSTS ───────────────────────────────────────────────────────────────────

  /// Stream em tempo real dos posts — usado pelo FeedScreen.
  /// Cada vez que um post é criado/editado no Firestore, o stream emite
  /// a lista atualizada e o feed reconstrói automaticamente.
  Stream<List<Post>> get postsStream {
    _postsStream ??= _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Post.fromJson({...d.data(), 'id': d.id}))
            .toList());
    return _postsStream!;
  }

  Future<Post> createPost({
    required Uint8List imageBytes,
    required String caption,
  }) async {
    final pid = _uuid.v4();

    // Fallback imediato: base64 para exibir sem depender do Storage
    final imageBase64Fallback = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

    // Upload da imagem para Firebase Storage
    String imageUrl = imageBase64Fallback; // começa com fallback
    try {
      final uploadedUrl = await _uploadImage('posts/$pid.jpg', imageBytes);
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        imageUrl = uploadedUrl;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DB] createPost upload falhou, usando base64: $e');
    }

    final post = Post(
      id: pid,
      ownerId: _currentUser!.id,
      ownerName: _currentUser!.name,
      ownerAvatarBase64: _currentUser!.avatarBase64 ?? '',
      imageBase64: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
    );

    // Salva no Firestore — o stream do feed detecta automaticamente
    await _db.collection('posts').doc(pid).set(post.toFirestore());

    // Atualiza lista local também para outras telas (perfil, ranking)
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    _pins.removeWhere((p) => p.postId == postId);
    _comments.removeWhere((c) => c.postId == postId);
    final batch = _db.batch();
    batch.delete(_db.collection('posts').doc(postId));
    final pinsSnap = await _db.collection('pins').where('postId', isEqualTo: postId).get();
    for (final d in pinsSnap.docs) batch.delete(d.reference);
    final commSnap = await _db.collection('comments').where('postId', isEqualTo: postId).get();
    for (final d in commSnap.docs) batch.delete(d.reference);
    await batch.commit();
    try { await _storage.ref('posts/$postId.jpg').delete(); } catch (_) {}
    notifyListeners();
  }

  Future<void> updatePostPrivacy(String postId, bool allowPublic) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].allowPublicPinsOverride = allowPublic;
    await _db.collection('posts').doc(postId).update({'allowPublicPinsOverride': allowPublic});
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

    final pinId = _uuid.v4();
    final pin = Pin(
      id: pinId, postId: postId,
      authorId: uid, authorName: _currentUser!.name,
      authorAvatarBase64: _currentUser!.avatarBase64 ?? '',
      xPercent: xPercent, yPercent: yPercent,
      targetLabel: targetLabel.trim(),
      score: score.clamp(0.0, 10.0),
      comment: comment, isPublic: isPublic,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    _pins.add(pin);
    await _db.collection('pins').doc(pinId).set(pin.toFirestore());
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

    final updates = <String, dynamic>{};
    if (targetLabel != null) { _pins[idx].targetLabel = targetLabel.trim(); updates['targetLabel'] = targetLabel.trim(); }
    if (score != null)       { _pins[idx].score = score.clamp(0.0, 10.0);  updates['score'] = score.clamp(0.0, 10.0); }
    if (comment != null)     { _pins[idx].comment = comment;                updates['comment'] = comment; }
    if (isPublic != null)    { _pins[idx].isPublic = isPublic;              updates['isPublic'] = isPublic; }
    _pins[idx].updatedAt = DateTime.now();
    updates['updatedAt'] = _pins[idx].updatedAt.toIso8601String();

    await _db.collection('pins').doc(pinId).update(updates);
    await _recalculatePost(_pins[idx].postId);
    notifyListeners();
    return null;
  }

  Future<void> deletePin(String pinId) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    final postId = _pins[idx].postId;
    _pins[idx].isDeleted = true;
    await _db.collection('pins').doc(pinId).update({'isDeleted': true});
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
    await _db.collection('posts').doc(postId).update({
      'notaMedia':        _posts[idx].notaMedia,
      'totalPins':        total,
      'totalAvaliadores': _posts[idx].totalAvaliadores,
    });
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
    final cid = _uuid.v4();
    final comment = PostComment(
      id: cid, postId: postId,
      authorId: _currentUser!.id, authorName: _currentUser!.name,
      authorAvatarBase64: _currentUser!.avatarBase64 ?? '',
      text: text.trim(), createdAt: DateTime.now(),
    );
    _comments.add(comment);
    final pIdx = _posts.indexWhere((p) => p.id == postId);
    if (pIdx != -1) {
      _posts[pIdx].totalComments =
          _comments.where((c) => c.postId == postId && !c.isDeleted).length;
      await _db.collection('posts').doc(postId).update(
          {'totalComments': _posts[pIdx].totalComments});
    }
    await _db.collection('comments').doc(cid).set(comment.toFirestore());
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
      await _db.collection('posts').doc(postId).update(
          {'totalComments': _posts[pIdx].totalComments});
    }
    await _db.collection('comments').doc(commentId).update({'isDeleted': true});
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
    final nid = _uuid.v4();
    final notif = AppNotification(
      id: nid, recipientId: recipientId,
      actorId: _currentUser!.id, actorName: _currentUser!.name,
      actorAvatarBase64: _currentUser!.avatarBase64 ?? '',
      type: type, postId: postId, pinId: pinId,
      body: body, createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    _db.collection('notifications').doc(nid).set(notif.toFirestore());
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final batch = _db.batch();
    for (final n in _notifications.where((n) => !n.isRead)) {
      n.isRead = true;
      batch.update(_db.collection('notifications').doc(n.id), {'isRead': true});
    }
    await batch.commit();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      await _db.collection('notifications').doc(id).update({'isRead': true});
    }
    notifyListeners();
  }

  // Exclui a conta do usuário atual
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    try {
      // 1. Deletar posts e imagens
      final userPosts = _posts.where((p) => p.ownerId == uid).toList();
      for (final post in userPosts) {
        await deletePost(post.id);
      }
      // 2. Deletar dados do usuário no Firestore
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid));
      final followsSnap = await _db.collection('follows')
          .where('followerId', isEqualTo: uid).get();
      for (final d in followsSnap.docs) batch.delete(d.reference);
      final followedSnap = await _db.collection('follows')
          .where('followingId', isEqualTo: uid).get();
      for (final d in followedSnap.docs) batch.delete(d.reference);
      final notifsSnap = await _db.collection('notifications')
          .where('recipientId', isEqualTo: uid).get();
      for (final d in notifsSnap.docs) batch.delete(d.reference);
      await batch.commit();
      // 3. Deletar do Firebase Auth
      await _auth.currentUser?.delete();
      // 4. Limpar estado local
      await logout();
    } catch (e) {
      if (kDebugMode) debugPrint('[DB] deleteAccount erro: $e');
      rethrow;
    }
  }

  // ── REFRESH ───────────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await _loadAllData();
    notifyListeners();
  }
}
