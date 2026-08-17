import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  // ---------------- USERS ----------------

  Future<List<AppUser>> allUsersExcept(String uid) async {
    final snap = await _users.orderBy('username').get();
    return snap.docs.where((d) => d.id != uid).map(AppUser.fromDoc).toList();
  }

  Future<void> updateProfilePhoto(String uid, String url) {
    return _users.doc(uid).update({'photoUrl': url});
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);
  }

  // ---------------- CHATS ----------------

  /// Fil de discussions (1-à-1 et groupes) auxquelles l'utilisateur participe,
  /// triées par dernier message.
  Stream<List<ChatThread>> myChats(String uid) {
    return _chats
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatThread.fromDoc).toList());
  }

  /// Retrouve la conversation 1-à-1 existante entre deux utilisateurs,
  /// ou en crée une nouvelle.
  Future<String> getOrCreateDirectChat(String uidA, String uidB) async {
    final ids = [uidA, uidB]..sort();
    final dmKey = ids.join('_');
    final existing = await _chats.where('dmKey', isEqualTo: dmKey).limit(1).get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final doc = await _chats.add({
      'isGroup': false,
      'dmKey': dmKey,
      'name': '',
      'memberIds': ids,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    required String creatorId,
  }) async {
    final allMembers = {...memberIds, creatorId}.toList();
    final doc = await _chats.add({
      'isGroup': true,
      'name': name,
      'memberIds': allMembers,
      'lastMessage': 'Groupe créé',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': creatorId,
    });
    return doc.id;
  }

  Stream<List<ChatMessage>> messages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    final chatRef = _chats.doc(chatId);
    await chatRef.collection('messages').add(message.toMap());

    String preview;
    switch (message.type) {
      case MessageType.text:
        preview = message.text ?? '';
        break;
      case MessageType.image:
        preview = '📷 Image';
        break;
      case MessageType.file:
        preview = '📎 ${message.fileName ?? 'Document'}';
        break;
    }
    await chatRef.update({
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- POSTS (publications) ----------------

  Stream<List<Post>> feed() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Post.fromDoc).toList());
  }

  Future<void> createPost({
    required String authorId,
    required String authorName,
    String? authorPhoto,
    required String text,
    String? imageUrl,
  }) {
    return _posts.add({
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'text': text,
      'imageUrl': imageUrl,
      'likes': <String>[],
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String postId, String uid, bool currentlyLiked) {
    return _posts.doc(postId).update({
      'likes': currentlyLiked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }

  Stream<List<PostComment>> comments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(PostComment.fromDoc).toList());
  }

  Future<void> addComment(String postId, {required String authorId, required String authorName, required String text}) async {
    final postRef = _posts.doc(postId);
    await postRef.collection('comments').add({
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await postRef.update({'commentCount': FieldValue.increment(1)});
  }
}
