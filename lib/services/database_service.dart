import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DatabaseService extends ChangeNotifier {
  static const String _usersKey = 'users_db';
  static const String _postsKey = 'posts_db';
  static const String _pinsKey = 'pins_db';
  static const String _currentUserKey = 'current_user_id';

  final _uuid = const Uuid();
  SharedPreferences? _prefs;

  List<AppUser> _users = [];
  List<Post> _posts = [];
  List<Pin> _pins = [];
  AppUser? _currentUser;

  List<AppUser> get users => _users;
  List<Post> get posts => _posts;
  List<Pin> get pins => _pins;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAll();
    await _loadCurrentUser();
    if (_posts.isEmpty) {
      await _seedDemoData();
    }
  }

  Future<void> _loadAll() async {
    final prefs = _prefs!;

    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final list = jsonDecode(usersJson) as List;
      _users = list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    }

    final postsJson = prefs.getString(_postsKey);
    if (postsJson != null) {
      final list = jsonDecode(postsJson) as List;
      _posts = list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    }

    final pinsJson = prefs.getString(_pinsKey);
    if (pinsJson != null) {
      final list = jsonDecode(pinsJson) as List;
      _pins = list.map((e) => Pin.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _loadCurrentUser() async {
    final id = _prefs!.getString(_currentUserKey);
    if (id != null) {
      try {
        _currentUser = _users.firstWhere((u) => u.id == id);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<void> _saveUsers() async {
    await _prefs!.setString(
      _usersKey,
      jsonEncode(_users.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> _savePosts() async {
    await _prefs!.setString(
      _postsKey,
      jsonEncode(_posts.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _savePins() async {
    await _prefs!.setString(
      _pinsKey,
      jsonEncode(_pins.map((p) => p.toJson()).toList()),
    );
  }

  // ─── AUTH ───────────────────────────────────────────────────────────────────

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return 'E-mail já cadastrado.';
    }
    final user = AppUser(
      id: _uuid.v4(),
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    await _saveUsers();
    await _setCurrentUser(user);
    notifyListeners();
    return null;
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      final user = _users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (user.passwordHash != _hashPassword(password)) {
        return 'Senha incorreta.';
      }
      await _setCurrentUser(user);
      notifyListeners();
      return null;
    } catch (_) {
      return 'E-mail não encontrado.';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs!.remove(_currentUserKey);
    notifyListeners();
  }

  Future<void> _setCurrentUser(AppUser user) async {
    _currentUser = user;
    await _prefs!.setString(_currentUserKey, user.id);
  }

  String _hashPassword(String password) {
    // Simple hash para demo (produção deve usar bcrypt ou similar)
    int hash = 0;
    for (int i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.toString();
  }

  // ─── USER ────────────────────────────────────────────────────────────────────

  Future<void> updateUserProfile({
    String? name,
    String? avatarBase64,
    bool? allowPublicPins,
  }) async {
    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx == -1) return;
    if (name != null) {
      _users[idx].name = name;
    }
    if (avatarBase64 != null) _users[idx].avatarBase64 = avatarBase64;
    if (allowPublicPins != null) {
      _users[idx].allowPublicPinsOnMyPosts = allowPublicPins;
    }
    _currentUser = _users[idx];
    await _saveUsers();
    // Atualizar posts do usuário
    for (var p in _posts.where((p) => p.ownerId == _currentUser!.id)) {
      p.ownerName = _users[idx].name;
      p.ownerAvatarBase64 = _users[idx].avatarBase64;
    }
    await _savePosts();
    notifyListeners();
  }

  // ─── POSTS ───────────────────────────────────────────────────────────────────

  Future<Post> createPost({
    required String imageBase64,
    required String caption,
  }) async {
    final post = Post(
      id: _uuid.v4(),
      ownerId: _currentUser!.id,
      ownerName: _currentUser!.name,
      ownerAvatarBase64: _currentUser!.avatarBase64,
      imageBase64: imageBase64,
      caption: caption,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);
    await _savePosts();
    notifyListeners();
    return post;
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    _pins.removeWhere((p) => p.postId == postId);
    await _savePosts();
    await _savePins();
    notifyListeners();
  }

  Future<void> updatePostPrivacy(String postId, bool allowPublic) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].allowPublicPinsOverride = allowPublic;
    await _savePosts();
    notifyListeners();
  }

  List<Post> getFeedPosts() {
    final list = List<Post>.from(_posts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> getUserPosts(String userId) {
    final list = _posts.where((p) => p.ownerId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> getRankingPosts({int minPins = 5}) {
    final list = _posts.where((p) => p.totalPins >= minPins).toList();
    list.sort((a, b) => b.notaMedia.compareTo(a.notaMedia));
    return list.take(3).toList();
  }

  Post? getPostById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── PINS ─────────────────────────────────────────────────────────────────

  /// Retorna pins visíveis para o usuário atual em um determinado post
  List<Pin> getVisiblePins(String postId) {
    final post = getPostById(postId);
    if (post == null) return [];
    final currentUserId = _currentUser?.id;
    final postOwner = getUserById(post.ownerId);
    final ownerAllowsPublic = (postOwner?.allowPublicPinsOnMyPosts ?? true) &&
        post.allowPublicPinsOverride;

    return _pins.where((pin) {
      if (pin.postId != postId) return false;
      if (pin.isDeleted) return false;

      // Dono do post vê tudo
      if (currentUserId == post.ownerId) return true;

      // Autor do pin sempre vê o próprio pin
      if (currentUserId == pin.authorId) return true;

      // Se dono não permite pins públicos → esconde de todos (exceto dono e autor)
      if (!ownerAllowsPublic) return false;

      // Pin público + dono permite → todos veem
      return pin.isPublic;
    }).toList();
  }

  List<Pin> getPinsForPost(String postId) {
    return _pins
        .where((p) => p.postId == postId && !p.isDeleted)
        .toList();
  }

  int getPinCountForUserOnPost(String postId, String userId) {
    return _pins
        .where((p) => p.postId == postId && p.authorId == userId && !p.isDeleted)
        .length;
  }

  Future<String?> createPin({
    required String postId,
    required double xPercent,
    required double yPercent,
    required String targetLabel,
    required double score,
    required String comment,
    required bool isPublic,
  }) async {
    final currentUserId = _currentUser!.id;
    final count = getPinCountForUserOnPost(postId, currentUserId);
    if (count >= 10) {
      return 'Você já atingiu o limite de 10 pins nesta foto.';
    }
    if (targetLabel.trim().isEmpty) {
      return 'Informe um título/alvo para o pin.';
    }

    final pin = Pin(
      id: _uuid.v4(),
      postId: postId,
      authorId: currentUserId,
      authorName: _currentUser!.name,
      authorAvatarBase64: _currentUser!.avatarBase64,
      xPercent: xPercent,
      yPercent: yPercent,
      targetLabel: targetLabel.trim(),
      score: score.clamp(0.0, 10.0),
      comment: comment,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _pins.add(pin);
    await _savePins();
    await _recalculatePost(postId);
    notifyListeners();
    return null;
  }

  Future<String?> editPin({
    required String pinId,
    String? targetLabel,
    double? score,
    String? comment,
    bool? isPublic,
  }) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return 'Pin não encontrado.';
    if (_pins[idx].authorId != _currentUser!.id) return 'Sem permissão.';

    if (targetLabel != null) _pins[idx].targetLabel = targetLabel.trim();
    if (score != null) _pins[idx].score = score.clamp(0.0, 10.0);
    if (comment != null) _pins[idx].comment = comment;
    if (isPublic != null) _pins[idx].isPublic = isPublic;
    _pins[idx].updatedAt = DateTime.now();

    await _savePins();
    await _recalculatePost(_pins[idx].postId);
    notifyListeners();
    return null;
  }

  Future<void> deletePin(String pinId) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    final postId = _pins[idx].postId;
    _pins[idx].isDeleted = true;
    await _savePins();
    await _recalculatePost(postId);
    notifyListeners();
  }

  Future<void> _recalculatePost(String postId) async {
    final activePins = _pins.where((p) => p.postId == postId && !p.isDeleted).toList();
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return;

    final total = activePins.length;
    final media = total > 0
        ? activePins.map((p) => p.score).reduce((a, b) => a + b) / total
        : 0.0;
    final avaliadores = activePins.map((p) => p.authorId).toSet().length;

    _posts[postIdx].notaMedia = double.parse(media.toStringAsFixed(1));
    _posts[postIdx].totalPins = total;
    _posts[postIdx].totalAvaliadores = avaliadores;

    await _savePosts();
  }

  AppUser? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── SEED DEMO DATA ──────────────────────────────────────────────────────────

  Future<void> _seedDemoData() async {
    // Criar usuários demo
    final u1 = AppUser(
      id: 'demo-user-1',
      name: 'Ana Costa',
      email: 'ana@demo.com',
      passwordHash: _hashPassword('123456'),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    final u2 = AppUser(
      id: 'demo-user-2',
      name: 'Pedro Lima',
      email: 'pedro@demo.com',
      passwordHash: _hashPassword('123456'),
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );
    final u3 = AppUser(
      id: 'demo-user-3',
      name: 'Mariana Silva',
      email: 'mariana@demo.com',
      passwordHash: _hashPassword('123456'),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );
    _users.addAll([u1, u2, u3]);
    await _saveUsers();

    // Criar posts demo com imagens de placeholder (cores sólidas base64)
    final post1 = Post(
      id: 'demo-post-1',
      ownerId: u1.id,
      ownerName: u1.name,
      imageBase64: _getDemoImageBase64(1),
      caption: 'Pôr do sol incrível na praia 🌅',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    );
    final post2 = Post(
      id: 'demo-post-2',
      ownerId: u2.id,
      ownerName: u2.name,
      imageBase64: _getDemoImageBase64(2),
      caption: 'Meu prato favorito do restaurante italiano 🍝',
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    );
    final post3 = Post(
      id: 'demo-post-3',
      ownerId: u3.id,
      ownerName: u3.name,
      imageBase64: _getDemoImageBase64(3),
      caption: 'Retrato no jardim botânico 🌸',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    final post4 = Post(
      id: 'demo-post-4',
      ownerId: u1.id,
      ownerName: u1.name,
      imageBase64: _getDemoImageBase64(4),
      caption: 'Arquitetura urbana 🏙️',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _posts.addAll([post1, post2, post3, post4]);

    // Criar pins demo para ranking funcionar (mínimo 5 pins)
    final demoScores1 = [9.0, 8.5, 9.5, 8.0, 9.0, 7.5];
    final demoScores2 = [7.0, 8.0, 6.5, 7.5, 8.5, 9.0];
    final demoScores3 = [9.5, 10.0, 9.0, 8.5, 9.0, 8.0];
    final demoScores4 = [5.0, 6.0, 5.5, 7.0, 6.5];

    final demoLabels = ['céu', 'luz', 'composição', 'cor', 'foco', 'enquadramento'];
    final authors = [u1, u2, u3];

    void addDemoPins(String postId, List<double> scores) {
      for (int i = 0; i < scores.length; i++) {
        final author = authors[i % authors.length];
        _pins.add(Pin(
          id: _uuid.v4(),
          postId: postId,
          authorId: author.id,
          authorName: author.name,
          xPercent: 20.0 + (i * 12.0),
          yPercent: 25.0 + (i * 8.0),
          targetLabel: demoLabels[i % demoLabels.length],
          score: scores[i],
          isPublic: true,
          createdAt: DateTime.now().subtract(Duration(hours: i + 1)),
          updatedAt: DateTime.now().subtract(Duration(hours: i + 1)),
        ));
      }
    }

    addDemoPins(post1.id, demoScores1);
    addDemoPins(post2.id, demoScores2);
    addDemoPins(post3.id, demoScores3);
    addDemoPins(post4.id, demoScores4);

    await _savePins();

    // Recalcular todos os posts
    for (final p in _posts) {
      await _recalculatePost(p.id);
    }
    notifyListeners();
  }

  String _getDemoImageBase64(int idx) {
    // Gera imagens coloridas simples como placeholder SVG convertido
    // Na prática seriam imagens reais, mas para demo usamos SVG data URI
    final colors = [
      '#1a1a4e,#7C3AED',
      '#1e3a2f,#10B981',
      '#2d1b4e,#EC4899',
      '#1a2d4e,#3B82F6',
    ];
    final pair = colors[(idx - 1) % colors.length].split(',');
    // Retorna string vazia — imagens serão tratadas com placeholder widget
    return 'demo:${pair[0]}:${pair[1]}:$idx';
  }
}
