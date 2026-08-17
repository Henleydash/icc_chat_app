import 'package:cloud_firestore/cloud_firestore.dart';

/// Profil d'un étudiant. Le document est stocké dans `users/{uid}`.
class AppUser {
  final String uid;
  final String username;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.username,
    this.email,
    this.photoUrl,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get initials {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

enum MessageType { text, image, file }

/// Un message dans `chats/{chatId}/messages/{messageId}`.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.text,
    this.mediaUrl,
    this.fileName,
    this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => MessageType.text,
      ),
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      fileName: data['fileName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'type': type.name,
        'text': text,
        'mediaUrl': mediaUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Une conversation (1-à-1 ou groupe) dans `chats/{chatId}`.
class ChatThread {
  final String id;
  final bool isGroup;
  final String name; // pour un DM : rempli côté client avec le nom de l'autre membre
  final List<String> memberIds;
  final String? photoUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;

  ChatThread({
    required this.id,
    required this.isGroup,
    required this.name,
    required this.memberIds,
    this.photoUrl,
    this.lastMessage = '',
    this.lastMessageAt,
  });

  factory ChatThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatThread(
      id: doc.id,
      isGroup: data['isGroup'] ?? false,
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      photoUrl: data['photoUrl'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Une publication dans `posts/{postId}`.
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String text;
  final String? imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime? createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.text,
    this.imageUrl,
    this.likes = const [],
    this.commentCount = 0,
    this.createdAt,
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhoto: data['authorPhoto'],
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Un commentaire dans `posts/{postId}/comments/{commentId}`.
class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  factory PostComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostComment(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
